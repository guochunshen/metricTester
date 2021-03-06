% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/runNulls.R
\name{runNulls}
\alias{runNulls}
\title{Randomize input CDM according to defined null models}
\usage{
runNulls(nulls.input, nulls, new_ = FALSE)
}
\arguments{
\item{nulls.input}{Prepped nulls.input object}

\item{nulls}{Optional. If not provided, defines the nulls as all of those in
defineNulls. If only a subset of those is desired, then nulls should take
the form of a character vector corresponding to named functions from defineNulls.
The available nulls can be determined by running names(defineNulls()). Otherwise,
if the user would like to define a new null on the fly, the argument nulls can take
the form of a named list of new functions (nulls). If the
latter, new_ must be set to TRUE.}

\item{new_}{Whether or not new nulls are being defined on the fly. Default is FALSE.
Set to TRUE if a new null is being used.}
}
\value{
A list of matrices. Each matrix is a product of a randomization of the input
CDM and one of the specified null models.
}
\description{
Given a prepared nulls.input object, will randomize a community data matrix according
to specified null models, and return a list of randomized CDMs.
}
\details{
Determine which nulls will be calculated by running names(defineNulls()).
If only a subset of these is desired, supply metrics with a character vector of the
named, available metrics.
}
\examples{
#simulate tree with birth-death process
tree <- geiger::sim.bdtree(b=0.1, d=0, stop="taxa", n=50)

sim.abundances <- round(rlnorm(5000, meanlog=2, sdlog=1)) + 1

cdm <- simulateComm(tree, richness.vector=10:25, abundances=sim.abundances)

prepped <- prepNulls(tree, cdm)

results <- runNulls(prepped)
}
\references{
Miller, E. T., D. R. Farine, and C. H. Trisos. 2016. Phylogenetic community
structure metrics and null models: a review with new methods and software.
Ecography DOI: 10.1111/ecog.02070
}

