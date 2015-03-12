#' Summarize metric performance of a series of summarized simulation results
#'
#' Flexible function that summarizes metric performance after reading in and testing
#' per-simulation results with a function like sesIndiv.
#'
#' @param summarized.results The results of a call to sesIndiv() or quadratOverall()
#' @param simulations Default is "all". Alternatively, can supply a vector of simulation
#' names to summarize the results over.
#' @param nulls Default is "all". Alternatively, can supply a vector of null model
#' names to summarize the results over.
#' @param concat.by Default is "both". Alternatively, can supply either "quadrat" or
#' "richness".
#' 
#' @details If an overall picture of metric performance is desired, this function can
#' provide it. It can also be used to summarize metric performance over a specific subset
#' of simulations, null models, and concatenation options. If provided with the results
#' of a call to quadratOverall, the options are more limited. Currently, if provided with
#' such a result, the assumption is
#' that there are three spatial simulations, "random", "filtering", and "competition". It
#' then assumes that any clustered or overdispersed quadrats for the random simulation,
#' or any overdispersed or clustered for the filtering or competition simulations,
#' respectively, count as typeI errors. It assumes that any quadrats that are not
#' clustered or overdispersed for the filtering or competition simulations, respectively,
#' count as typeII errors.
#'
#' @return A data frame of summarized results
#'
#' @export
#'
#' @references Miller, Trisos and Farine.
#'
#' @examples
#' #not run
#' #results <- readIn()
#' #summ <- sesIndiv(results)
#' #examp <- metricPerformance(summ)

metricPerformance <- function(summarized.results, simulations="all", nulls="all",
	concat.by="both")
{
	if(simulations=="all")
	{
		simulations <- unique(summarized.results$simulation)
	}
	#complicated if statement here. it says if the specified simulations do not contain
	#an entry of character "all" and there is any difference between the specified sims
	#and the unique simulations in the summarized.results table, throw an error
	else if(all(!(simulations %in% "all")) &
		length(setdiff(simulations, unique(summarized.results$simulation))) > 0)
	{
		stop("Specified simulations do not match those in the results table")
	}
	else
	{
		simulations <- simulations
	}

	if(concat.by=="both")
	{
		concat.by <- unique(summarized.results$concat.by)
	}
	else if(all(!(concat.by %in% "both")) &
		length(setdiff(concat.by, unique(summarized.results$concat.by))) > 0)
	{
		stop("concat.by must be set to quadrat, richness, or both")
	}
	else
	{
		concat.by <- concat.by
	}

	if(nulls=="all")
	{
		nulls <- unique(summarized.results$null.model)
	}
	else if(all(!(nulls %in% "all")) &
		length(setdiff(nulls, unique(summarized.results$null.model))) > 0)
	{
		stop("Specified nulls do not match those in the results table")
	}
	else
	{
		nulls <- nulls
	}

	metrics <- unique(summarized.results$metric)
	typeI <- c()
	typeII <- c()
	
	if(names(summarized.results)[5] == "total.runs")
	{
		for(i in 1:length(metrics))
		{
			temp <- summarized.results[summarized.results$metric %in% metrics[i]
				& summarized.results$simulation %in% simulations
				& summarized.results$concat.by %in% concat.by
				& summarized.results$null.model %in% nulls,]
			temp$typeIrate <- 100 * temp$typeI/temp$total.runs
			temp$typeIIrate <- 100 * temp$typeII/temp$total.runs
			typeI[i] <- mean(temp$typeIrate, na.rm=TRUE)
			typeII[i] <- mean(temp$typeIIrate, na.rm=TRUE)
		}
	}

	else if(names(summarized.results)[5] == "clustered")
	{
		#generate some simulation-specific data frames
		random <- summarized.results[summarized.results$metric %in% metrics
			& summarized.results$simulation == "random"
			& summarized.results$concat.by %in% concat.by
			& summarized.results$null.model %in% nulls,]
		filtering <- summarized.results[summarized.results$metric %in% metrics
			& summarized.results$simulation == "filtering"
			& summarized.results$concat.by %in% concat.by
			& summarized.results$null.model %in% nulls,]
		competition <- summarized.results[summarized.results$metric %in% metrics
			& summarized.results$simulation == "competition"
			& summarized.results$concat.by %in% concat.by
			& summarized.results$null.model %in% nulls,]

		#define typeI & II error rates for each of these
		random$typeIrate <- 100 *
			(random$clustered + random$overdispersed)/random$total.quadrats
		random$typeIIrate <- NA

		filtering$typeIrate <- 100 * filtering$overdispersed/filtering$total.quadrats
		filtering$typeIIrate <- 100 * 
			(filtering$total.quadrats - filtering$clustered)/filtering$total.quadrats

		competition$typeIrate <- 100 *
			competition$clustered/competition$total.quadrats
		competition$typeIIrate <- 100 * 
			(competition$total.quadrats -
			competition$overdispersed)/competition$total.quadrats

		#redefine summarized.results
		summarized.results <- rbind(random, filtering, competition)

		for(i in 1:length(metrics))
		{
			temp <- summarized.results[summarized.results$metric %in% metrics[i]
				& summarized.results$simulation %in% simulations
				& summarized.results$concat.by %in% concat.by
				& summarized.results$null.model %in% nulls,]
			typeI[i] <- mean(temp$typeIrate, na.rm=TRUE)
			typeII[i] <- mean(temp$typeIIrate, na.rm=TRUE)
		}
	}

	else
	{
		stop("Unexpected function input")
	}

	results <- data.frame(metrics, typeI, typeII)
	results
}