#' Calculate a species' trait field
#'
#' Calculate the similarity in trait space of a species to those it occurs with.
#'
#' @param trait.distance Symmetrical matrix summarizing pairwise trait distances. If
#' it contains.
#' @param picante.cdm A picante-style community data matrix with sites as rows, and
#' species as columns.
#' @param metric Phylogenetic metric of choice (see details).
#' 
#' @details This function is being deprecated. This and the rest of the first generation
#' of field functions are being replaced by a two-step process akin to the calcMetrics
#' set of functions. The user first preps the data with a prep function, then runs the
#' desired metrics and nulls over the prepped object. This allows sets of metrics to be
#' calculated over the same randomized matrix, rather than having to repeatedly generate
#' the same random matrix for each metric.
#' The trait distance matrix should be symmetrical and "complete". See example.
#' Currently this is only programmed to use either non-abundance-weighted mean
#' pairwise or interspecific abundance-weighted mean pairwise phylogenetic distance.
#' Importantly, we are in the process of generalizing the phylo & trait
#' field functions, so they operate more like the calcMetrics functions. In other words,
#' the user will prep their data first, then choose which metrics to calculate and the
#' function will detect whether to calculate phylo or trait fields based on the inputs.
#' Take note of this, as code using the current forms of these functions is liable to
#' break when these updates are made.
#'
#' @return Named vector of species' trait fields. 
#'
#' @export
#'
#' @references Miller, Wagner, Harmon & Ricklefs. In review. Radiating despite a lack of
#' character: closely related, morphologically similar, co-occurring honeyeaters have
#' diverged ecologically.
#'
#' @examples
#' #simulate tree with birth-death process
#' tree <- geiger::sim.bdtree(b=0.1, d=0, stop="taxa", n=50)
#'
#' #simulate trait evolution up the tree. Make 2-d trait space and find distances between
#' #species in that space
#' traits <- evolveTraits(tree)
#'
#' #calculate the distances betweeen species
#' dists <- as.matrix(dist(traits[[2]], diag=TRUE, upper=TRUE))
#'
#' #simulate log-normal abundances
#' sim.abundances <- round(rlnorm(5000, meanlog=2, sdlog=1)) + 1
#'
#' #simulate a community data matrix with these inputs
#' cdm <- simulateComm(tree, richness.vector=10:25, abundances=sim.abundances)
#'
#' #example trait field calculations
#' exampleField <- traitField(trait.distance=dists, picante.cdm=cdm, metric="naw.mpd")

traitField <- function(trait.distance, picante.cdm, metric)
{
	#use the .deprecate function from geiger, in your utils.R file to warn this function
	#will be deprecated soon
	.deprecate("traitField", "calcField")
	
	#if user passes a trait.distance matrix that contains species that are not in the cdm,
	#prune the tree down to those species
	if(length(setdiff(rownames(trait.distance), colnames(picante.cdm))) > 0)
	{
		print("Pruning distance matrix to include only species in picante.cdm")
		trait.distance <- trait.distance[rownames(trait.distance) %in% colnames(picante.cdm),
			colnames(trait.distance) %in% colnames(picante.cdm)]
	}
	
	#if user passes cdm that contains species that are not in trait.distance, throw error
	if(length(setdiff(colnames(picante.cdm), rownames(trait.distance))) > 0)
	{
		stop("You have species in your picante.cdm that are not in your distance matrix")
	}
	
	#calculate the metric for each cell in the cdm
	if(metric=="naw.mpd")
	{
		cellResults <- modifiedMPD(samp=picante.cdm, dis=trait.distance,
			abundance.weighted=FALSE)
	}
	else if(metric=="interspecific")
	{
		cellResults <- modifiedMPD(samp=picante.cdm, dis=trait.distance,
			abundance.weighted="interspecific")
	}
	else if(metric=="naw.mntd")
	{
		cellResults <- mntd(samp=picante.cdm, dis=trait.distance,
			abundance.weighted=FALSE)
	}
	else if(metric=="aw.mntd")
	{
		cellResults <- mntd(samp=picante.cdm, dis=trait.distance, abundance.weighted=TRUE)
	}
	else
	{
		stop("metric must be one of 'naw.mpd', 'interspecific', 'naw.mntd' or 'aw.mntd'")
	}

	#go into a simple for loop that for each species, takes a weighted mean of the vector
	#of assemblage-specific metric values. if the species is absent, the weight will be
	#zero and it won't be included, so don't need to do any subsetting. if non-abundance-
	#weighted take a "weighted" mean where weights are either 0s or 1s
	results <- c()
	for(i in 1:dim(trait.distance)[1])
	{
		if(metric=="naw.mpd" | metric=="naw.mntd")
		{
			#derive a quick vector of presence-absence style weights so that if the metric
			#is not abundance-weighted it treats a presence as a 1, otherwise a 0.
			naWeights <- picante.cdm[,i]
			naWeights[naWeights > 0] <- 1

			results[i] <- weighted.mean(x=cellResults, w=naWeights, na.rm=TRUE)
		}
		else if(metric=="interspecific" | metric=="aw.mntd")
		{
			results[i] <- weighted.mean(x=cellResults, w=picante.cdm[,i], na.rm=TRUE)
		}
	}
	
	#give the vector names and return
	names(results) <- colnames(picante.cdm)
	results
}
