#' @include MsExperimentFiles.R

#' @title Managing Mass Spectrometry Experiments
#'
#' @aliases MsExperiment-class MsExperiment
#'
#' @description
#'
#' The `MsExperiment` class allows the storage and management of all
#' aspects related to a complete proteomics or metabolomics mass
#' spectrometry experiment. This includes experimantal design (i.e. a table
#' with samples), raw mass spectromtry data as spectra and chromatograms,
#' quantitative features, and identification data or any other relevant data
#' files.
#'
#' For details, see https://rformassspectrometry.github.io/MsExperiment
#'
#' This package is part of the RforMassSpectrometry initiative:
#' https://www.rformassspectrometry.org/
#'
#' @section General information:
#'
#' An experiment is typically composed of several items
#'
#' - Description and information (covariates etc) of each sample from
#'   the experiment. These are stored in the `sampleData` slot as a
#'   `DataFrame`, each row describing a sample with columns containing
#'   all relevant information on that sample.
#'
#' - Files to data or annotations. These are stored in the
#'   `@experimentFiles` slot as an instance of class `MsExperimentFiles`.
#'
#' - General metadata about the experiment, stored as a `list` in the
#'   `@metadata` slot.
#'
#' - Mass spectrometry data. Sectra and their metadata are stored as
#'   an `[Spectra::Spectra()]` object in the `spectra` slot. Chromatographic
#'   data is not yet supported but will be stored as a `Chromatograms()`
#'   object in the `@chromatorgrams` slot.
#'
#' - Quantification data is stored as `QFeatures` or
#'   `SummarizedExperiment` objects in the `@qdata` slot and can be accessed or
#'   replaced with the `qdata()` or `qdata<-` functions, respectively.
#'
#' - Any additional data, be it other spectra data, or proteomics
#'   identification data (i.e peptide-spectrum matches defined as
#'   `PSM` objects) can be added as elements to the list stored in
#'   the `otherData` slot.
#'
#' The *length* of a `MsExperiment` is defined by the number of samples (i.e.
#' the number of rows of the object's `sampleData`). A `MsExperiment` with two
#' samples will thus have a length of two, independently of the number of files
#' or length of raw data in the object. This also defines the subsetting of the
#' object using the `[` function which will always subset by samples. See the
#' section for filtering and subsetting below for more information.
#'
#' `MsExperiment` objects can be created using the `MsExperiment()` function
#' providing the data with the parameters listed below. If the
#' [Spectra::Spectra()]
#' object provided with the `spectra` param uses a `MsBackendSql` backend,
#' sample data could be retrieved from the associated SQL database (see
#' section *Using `MsExperiment` with `MsBackendSql`* in the vignette for
#' details). Alternatively, it is also possible to subsequently add data and
#' information to an existing `MsExperiment`.
#' Finally, with the [readMsExperiment()] function it is possible to create
#' a `MsExperiment` by importing MS spectra data directly from provided data
#' files. See examples below or the package vignette for more information.
#'
#' @section Accessing data:
#'
#' Data from an `MsExperiment` object can be accessed with the dedicated
#' accessor functions:
#'
#' - `experimentFiles()`, `experimentFiles<-`: gets or sets experiment files.
#'
#' - `length()`: get the *length* of the object which represents the number of
#'   samples availble in the object's `sampleData`.
#'
#' - `metadata()`, `metadata<-`: gets or sets the object's metadata.
#'
#' - `sampleData()`, `sampleData<-`: gets or sets the object's sample data
#'   (i.e. a `DataFrame` containing sample descriptions).
#'
#' - `spectra()`, `spectra<-`: gets or sets spectra data. `spectra()` returns a
#'   [Spectra::Spectra()] object, `spectra<-` takes a `Spectra` data as input
#'   and returns the updated `MsExperiment`.
#'
#' - `spectraSampleIndex()`: depending on parameter `duplicates` it returns
#'   either an `integer` (`duplicates = "first"`, the default) or a `list`
#'   (`duplicates = "keep"`) of length equal to the number of spectra within
#'   the object with the indices of the sample(s) (in `sampleData()`) a
#'   spectrum is assigned to. With `duplicates = "first"`, an `integer` with
#'   the index is returned for each spectrum. If a spectrum was assigned to
#'   more than one sample a warning is shown and only the first sample index
#'   is returned for that spectrum. For `duplicates = "keep"`, assignments are
#'   returned as a `list` of `integer` vectors, each element being the
#'   index(es) of the sample(s) a spectrum is assigned to. For spectra that are
#'   not linked to any sample an `NA_integer_` is returned as index for
#'   `duplicates = "first"` and an empty integer (`integer()`) for
#'   `duplicates = "keep"`.
#'   Note that the default `duplicates = "first"` will work in almost all use
#'   cases, as generally, a spectrum will be assigned to a single sample.
#'
#' - `qdata()`, `qdata<-`: gets or sets the quantification data, which can be a
#'   `QFeatures` or `SummarizedExperiment`.
#'
#' - `otherData()` , `otherData<-`: gets or sets the addition data
#'   types, stored as a `List` in the object's `otherData` slot.
#'
#' @section Linking sample data to other experimental data:
#'
#' To start with, an `MsExperiment` is just a loose collection of files and data
#' related to an experiment, no explicit links or associactions are present
#' between the samples and related data. Such links can however be created with
#' the `linkSampleData()` function. This function can establish links between
#' individual (or all) samples within the object's `sampleData` to individual,
#' or multiple, data elements or files, such as `Spectra` or raw data files.
#'
#' The presence of such links enables a (consistent) subsetting of an
#' `MsExperiment` by samples. Thus, once the link is defined, any subsetting by
#' sample will also correctly subset the linked data. All other, not linked,
#' data elements are always retained as in the original `MsExperiment`.
#'
#' To be able to link different elements within an `MsExperiment` it is also
#' required to *identify* them with a consistent naming scheme. The naming
#' scheme of slots and data elements within follows an SQL-like scheme, in which
#' the variable (element) is identified by the name of the database table,
#' followed by a `"."` and the name of the database table column. For
#' `MsExperiment`, the naming scheme is defined as
#' `"<slot name>.<element name>"`. A column called `"sample_name"` within the
#' `sampleData` data frame can thus be addressed with
#' `"sampleData.sample_name"`, while `spectra.msLevel` would represent the
#' spectra variable called `msLevel` within the `Spectra` stored in the
#' `spectra` slot.
#'
#' Links between sample data rows and any other data element are stored as
#' `integer` matrices within the `@sampleDataLinks` slot of the object (see also
#' the vignette for examples and illustrations). The first column of a matrix
#' is always the index of the sample, and the second column the index of the
#' element that is linked to that sample, with one row per element.
#' Links can be defined/added with the `linkSampleData()` function which adds
#' a relationship between rows in `sampleData` to elements in any other data
#' within the `MsExperiment` that are specified with parameter `with`.
#' `linkSampleData()` supports two different ways to define the link:
#'
#' - Parameter `with` defines the data to which the link should be established.
#'   To link samples to raw data files that would for example be available as a
#'   `character` in an element called `"raw_files"` within the object's
#'   `experimentFiles`, `with = experimentFiles.raw_files` would have to be
#'   used. Next it is required to specify which samples should be linked with
#'   which elements in `with`. This needs to be defined with the parameters
#'   `sampleIndex` and `withIndex`, both are expected to be `integer` vectors
#'   specifying which sample in `sampleData` should be linked to which element
#'   in `with` (see examples below or vignette for examples and details).
#'
#' - As an alternative way, a link could be defined with an SQL-like syntax
#'   that relates a column in `sampleData` to a column/element in the data to
#'   which the link should be established. To link for example individual
#'   spectra to the corresponding samples
#'   `with = "sampleData.raw_file = spectra.dataOrigin"` could be used assuming
#'   that `sampleData` contains a column named `"raw_file"` with the (full path)
#'   of the raw data file for each sample from which the spectra were imported.
#'   In this case both `sampleIndex` and `withIndex` can be omitted, but it is
#'   expected/required that the columns/elements from `sampleData` and the data
#'   element to which the link should be established contain matching values.
#'
#' Note that `linkSampleData` will **replace** a previously existing link to the
#' same data element.
#'
#' - `spectraSampleIndex()` is a convenience function that extracts for each
#'   spectrum in the object's `spectra()` the index of the sample it is
#'   associated with (see function's help above for more information).
#'
#' @section Subsetting and filtering:
#'
#' - `[`: `MsExperiment` objects can be subset **by samples** with `[i]`
#'   where `i` is the index or a logical defining to which samples the data
#'   should be subset. Subsetting by sample will (correctly) subset all
#'   linked data to the respective samples. If multiple samples are linked to
#'   the same data element, subsetting might duplicate that data element. This
#'   duplication of *n:m* relationships between samples to elements does however
#'   not affect data consistency (see examples below for more information).
#'   Not linked data (slots) will be returned as they are. Subsetting in
#'   arbitrary order is supported.
#'   See the vignette for details and examples.
#'
#' - `filterSpectra()`: subsets the `Spectra` within an `MsExperiment` using a
#'   provided filter function (parameter `filter`). Parameters for the filter
#'   function can be passed with parameter `...`. Any of the filter functions
#'   of a [Spectra::Spectra()] object can be passed with parameter `filter`.
#'   Possibly present relationships between samples and spectra (*links*, see
#'   also `linkSampleData()`) are updated. Filtering affects only the spectra
#'   data of the object, none of the other slots and data (e.g. `sampleData`)
#'   are modified.
#'   The function returns an `MsExperiment` with the filtered `Spectra` object.
#'
#' @return See help of the individual functions.
#'
#' @param spectra [Spectra::Spectra()] object with the MS spectra data of the
#'     experiment.
#'
#' @param drop for `[`: ignored.
#'
#' @param duplicates for `spectraSampleIndex()`: `character(1)` defining the
#'     type of result returned by `spectraSampleIndex()`. With
#'     `duplicates = "first"` an `integer` vector is returned with the first
#'     match while `duplicates = "keep"` returns a `list` of `integer` with
#'     the index of all matches.
#'
#' @param experimentFiles [MsExperimentFiles()] defining (external) files
#'     to data or annotation.
#'
#' @param filter for `filterSpectra()`: any filter function supported by
#'     [Spectra::Spectra()] to filter the spectra object (such as `filterRt` or
#'     `filterMsLevel`). Parameters for the filter function can be passed
#'     through `...`.
#'
#' @param i for `[`: an `integer`, `character` or `logical` referring to the
#'     indices or names (rowname of `sampleData`) of the samples to subset.
#'
#' @param j for `[`: not supported.
#'
#' @param object an `MsExperiment`.
#'
#' @param otherData `List` with arbitrary additional (*other*) information or
#'     data.
#'
#' @param qdata `QFeatures` or `SummarizedExperiment` with the quantification
#'     data.
#'
#' @param sampleData `DataFrame` (or `data.frame`) with information on
#'     individual samples of the experiment.
#'
#' @param sampleIndex for `linkSampleData()`: `integer` with the indices of the
#'     samples in `sampleData(object)` that should be linked.
#'
#' @param subsetBy for `linkSampleData()`: optional `integer(1)` defining the
#'     dimension on which the subsetting will occurr on the linked data.
#'     Defaults to `subsetBy = 1L` thus subsetting will happen on the first
#'     dimension (rows or elements).
#'
#' @param with for `linkSampleData()`: `character(1)` defining the data to which
#'     samples should be linked. See section *Linking sample data to other
#'     experimental data* for details.
#'
#' @param withIndex for `linkSampleData()`: `integer` with the indices of the
#'     elements in `with` to which the samples (specified by `sampleIndex`)
#'     should be linked to.
#'
#' @param x an `MsExperiment`.
#'
#' @param ... optional additional parameters. For `filterSpectra()`: parameters
#'     to be passed to the filter function (parameter `filter`).
#'
#' @name MsExperiment
#'
#' @importFrom S4Vectors List DataFrame
#'
#' @importClassesFrom S4Vectors List
#'
#' @author Laurent Gatto, Johannes Rainer
#'
#' @examples
#'
#' ## An empty MsExperiment object
#' msexp <- MsExperiment()
#' msexp
#'
#' example(MsExperimentFiles)
#' experimentFiles(msexp) <- fls
#' msexp
#'
#' ## Linking samples to data elements
#'
#' ## Create a small experiment
#' library(S4Vectors)
#' mse <- MsExperiment()
#' sd <- DataFrame(sample_id = c("QC1", "QC2"),
#'                 sample_name = c("QC Pool", "QC Pool"),
#'                 injection_idx = c(1, 3))
#' sampleData(mse) <- sd
#'
#' ## define file names containing spectra data for the samples and
#' ## add them, along with other arbitrary files to the experiment
#' fls <- dir(system.file("sciex", package = "msdata"), full.names = TRUE)
#' experimentFiles(mse) <- MsExperimentFiles(
#'     mzML_files = fls,
#'     annotations = "internal_standards.txt")
#'
#' ## Link samples to data files: first sample to first file in "mzML_files",
#' ## second sample to second file in "mzML_files"
#' mse <- linkSampleData(mse, with = "experimentFiles.mzML_files",
#'     sampleIndex = c(1, 2), withIndex = c(1, 2))
#'
#' ## Link all samples to the one file in "annotations"
#' mse <- linkSampleData(mse, with = "experimentFiles.annotations",
#'     sampleIndex = c(1, 2), withIndex = c(1, 1))
#' mse
#'
#' ## Import the spectra data and add it to the experiment
#' library(Spectra)
#' spectra(mse) <- Spectra(fls, backend = MsBackendMzR())
#'
#' ## Link each spectrum to the respective sample. We use the alternative
#' ## link definition that does not require sampleIndex and withIndex but
#' ## links elements based on matching values in the specified data elements.
#' ## We need to add the full file name as an additional column to sampleData
#' ## in order to allow matching this file names with the value in
#' ## spectra(mse)$dataOrigin which contains the original file names from which
#' ## the spectra were imported.
#' sampleData(mse)$raw_file <- normalizePath(fls)
#'
#' ## The links can be added using the short notation below
#' mse <- linkSampleData(mse, with = "sampleData.raw_file = spectra.dataOrigin")
#' mse
#'
#' ## With sampleData links present, any subsetting of the experiment by sample
#' ## will ensure that all linked elements are subset accordingly
#' b <- mse[2]
#' b
#' sampleData(b)
#' experimentFiles(b)$mzML_files
#'
#' ## The `spectraSampleIndex()` function returns, for each spectrum, the
#' ## index in the object's `sampleData` to which it is linked/assigned
#' spectraSampleIndex(mse)
#'
#' ## Subsetting with duplication of n:m sample to data relationships
#' ##
#' ## Both samples were assigned above to one "annotation" file in
#' ## `experimentFiles`:
#' experimentFiles(mse[1])[["annotations"]]
#' experimentFiles(mse[2])[["annotations"]]
#'
#' ## Subsetting will always keep the relationship between samples and linked
#' ## data elements. Subsetting will however possibly duplicate data elements
#' ## that are shared among samples. Thus, while in the original object the
#' ## element "annotations" has a single entry, subsetting with [1:2] will
#' ## result in an MsExperiment with duplicated entries in "annotations"
#' experimentFiles(mse)[["annotations"]]
#' experimentFiles(mse[1:2])[["annotations"]]
#'
#' ## Spectra within an MsExperiment can be filtered/subset with the
#' ## `filterSpectra` function and any of the filter functions supported
#' ## by `Spectra` objects. Below we restrict the spectra data to spectra
#' ## with a retention time between 200 and 210 seconds.
#' res <- filterSpectra(mse, filterRt, rt = c(200, 210))
#' res
#'
#' ## The object contains now much less spectra. The retention times for these
#' rtime(spectra(res))
#'
#' ## Relationship between samples and spectra was preserved by the filtering
#' a <- res[1L]
#' spectra(a)
NULL

#' @name MsExperiment-class
#'
#' @docType class
#'
#' @exportClass MsExperiment
#'
#' @slot experimentFiles An instance of class `MsExperimentFiles` or `NULL`.
#'
#' @slot spectra An instance of class `Spectra` or `NULL`.
#'
#' @slot qdata An instance of class `QFeatures`, `SummarizedExperiment` or
#'     `NULL`.
#'
#' @slot otherData A `List` to store any additional data objects.
#'
#' @slot sampleData A `DataFrame` documenting the experimental design.
#'
#' @slot sampleDataLinks A `List` with link definitions between samples and
#'     data elements. Should not be directly accessed or modified by the user.
#'
#' @slot metadata A `list` to store additional metadata.
#'
#' @rdname MsExperiment
#'
#' @importClassesFrom S4Vectors SimpleList
#'
#' @importClassesFrom S4Vectors Annotated
#'
#' @importFrom S4Vectors DataFrame
setClass("MsExperiment",
         contains = "Annotated",
         slots = c(
             experimentFiles = "MsExperimentFiles",
             spectra = "Spectra_OR_Null",
             qdata = "QFeatures_OR_SummarizedExperiment_OR_Null",
             ## chromatograms = "Chromatograms",
             otherData = "List",
             sampleData = "DataFrame",
             sampleDataLinks = "List"),
         prototype = prototype(
             experimentFiles = MsExperimentFiles(),
             spectra = NULL,
             qdata = NULL,
             otherData = List(),
             sampleData = DataFrame(),

             sampleDataLinks = new(
                 "SimpleList", elementMetadata =
                                   DataFrame(subsetBy = integer())))
         )

#' @rdname MsExperiment
#'
#' @export
MsExperiment <- function(experimentFiles = MsExperimentFiles(),
                         otherData = List(),
                         qdata = NULL,
                         sampleData = DataFrame(),
                         spectra = NULL) {
    if (!length(sampleData) && length(spectra) &&
        inherits(spectra, "Spectra") &&
        inherits(spectra@backend, "MsBackendSql")) {
        sampleData <- .db_get_sample_data(spectra)
        slink <- .db_get_sample_spectra_link(spectra)
    } else slink <- matrix(ncol = 2, nrow = 0)
    res <- new("MsExperiment", experimentFiles = experimentFiles,
               otherData = otherData, qdata = qdata,
               sampleData = DataFrame(sampleData), spectra = spectra)
    if (length(slink)) {
        res@sampleDataLinks[["spectra"]] <- slink
        mcols(res@sampleDataLinks)["spectra", "subsetBy"] <- 1L
    }
    res
}

#' @rdname MsExperiment
#'
#' @param object An instance of class `MsExperiment`.
#'
#' @importFrom Spectra msLevel
#'
#' @exportMethod show
setMethod("show", "MsExperiment", function(object) {
    mess <- "Object of class"
    if (.ms_experiment_is_empty(object))
        mess <- "Empty object of class"
    cat(mess, class(object), "\n")
    ## Show experiment files
    if (length(experimentFiles(object)))
        cat(" Files:", paste(names(experimentFiles(object)),
                             collapse = ", "), "\n")
    ## Show spectra
    if (!is.null(object@spectra)) {
        mstab <- table(msLevel(object@spectra))
        cat(" Spectra:", paste0("MS", names(mstab), " (", mstab, ")"),
            "\n")
    }
    ## Show quantitative data
    if (!is.null(object@qdata)) {
        if (inherits(object@qdata, "SummarizedExperiment"))
            cat( " SummarizedExperiment:",
                nrow(object@qdata), "feature(s)\n")
        else ## QFeatures
            cat( " QFeatures:",
                length(object@qdata), "assay(s)\n")

    }
    ## Show other data
    if (length(object@otherData)) {
        cat(" Other data:",
            paste(names(object@otherData), collapse = ", "),
            "\n")
    }
    ## Show experiment/sample data
    if (nrow(object@sampleData)) {
        cat(" Experiment data:",
            nrow(object@sampleData), "sample(s)\n")
    }
    lnks <- object@sampleDataLinks
    if (length(lnks)) {
        cat(" Sample data links:\n")
        for (i in seq_along(lnks)) {
            if (mcols(lnks)$subsetBy[i] == 2)
                cols <- " column(s).\n"
            else cols <- " element(s).\n"
            cat("  - ", names(lnks)[i], ": ", length(unique(lnks[[i]][, 1L])),
                " sample(s) to ", length(unique(lnks[[i]][, 2L])), cols,
                sep = "")
        }
    }
})

#' @rdname MsExperiment
#'
#' @exportMethod length
setMethod("length", "MsExperiment", function(x) {
    nrow(sampleData(x))
})

## ------------------------------##
##     Getters and setters       ##
## ------------------------------##

#' @export
#'
#' @importFrom ProtGenerics spectra
#'
#' @rdname MsExperiment
setMethod("spectra", "MsExperiment", function(object) object@spectra)

#' @importMethodsFrom ProtGenerics spectra<-
#'
#' @export
#'
#' @rdname MsExperiment
setReplaceMethod("spectra", "MsExperiment", function(object, value) {
    stopifnot(inherits(value, "Spectra"))
    stopifnot(inherits(object, "MsExperiment"))
    object@spectra <- value
    object
})


#' @rdname MsExperiment
#'
#' @export
otherData <- function(object) {
    stopifnot(inherits(object, "MsExperiment"))
    object@otherData

}

#' @rdname MsExperiment
#'
#' @export
`otherData<-` <- function(object, value) {
    object@otherData <- value
    object
}

#' @rdname MsExperiment
#'
#' @export
linkSampleData <- function(object, with = character(),
                           sampleIndex = seq_len(nrow(sampleData(object))),
                           withIndex = integer(), subsetBy = 1L) {
    if (!length(with))
        return(object)
    subsetBy <- as.integer(subsetBy[1L])
    if (is.na(subsetBy))
        stop("'subsetBy' needs to be an integer of length 1")
    if (!length(withIndex)) {
        link_string <- .parse_join_string(with)
        if (link_string[1L] == "sampleData") {
            from <- paste0(link_string[c(1, 2)], collapse = ".")
            to_slot <- link_string[3L]
            with <- paste0(link_string[c(3, 4)], collapse = ".")
        } else if (link_string[3L] == "sampleData") {
            from <- paste0(link_string[c(3, 4)], collapse = ".")
            to_slot <- link_string[1L]
            with <- paste0(link_string[c(1, 2)], collapse = ".")
        } else stop("one of the slot names has to be 'sampleData'.")
        link <- .link_matrix(.get_element(object, from),
                             .get_element(object, with))
        if (nrow(link) == 0)
            warning("no matches found for '", with, "'")
    } else {
        sampleIndex <- as.integer(sampleIndex)
        withIndex <- as.integer(withIndex)
        sampleIndex <- sampleIndex[!is.na(sampleIndex)]
        withIndex <- withIndex[!is.na(withIndex)]
        if (length(sampleIndex) != length(withIndex))
            stop("Length of 'sampleIndex' and 'withIndex' have to match")
        link <- cbind(sampleIndex, withIndex)
    }
    withl <- unlist(strsplit(with, split = ".", fixed = TRUE))
    if (withl[1L] %in% c("spectra", "qdata")) {
        with <- withl[1L]
        if (with == "qdata")
            subsetBy <- 2L
    } else if (length(withl) < 2)
        stop("'with' should be a 'character' with the name of the slot and",
             " the name of element separated by a '.'. ",
             "See ?linkSampleData for examples")
    .add_sample_data_link(object, link, with = with, subsetBy = subsetBy)
}

#' @rdname MsExperiment
#'
#' @export
setMethod("[", "MsExperiment", function(x, i, j, ..., drop = FALSE) {
    if (!missing(j))
        stop("Only subsetting with '[i]' is supported.")
    li <- length(i)
    if (is.character(i)) {
        i <- match(i, rownames(sampleData(x)))
        if (any(is.na(i)))
            warning(sum(is.na(i)), " of ", li, " values could not be ",
                    "matched to rownames of 'sampleData(x)'")
        i <- i[!is.na(i)]
    }
    if (is.logical(i)) {
        if (li != nrow(sampleData(x)))
            stop("if 'i' is logical its length has to match the number of ",
                 "samples in 'x'.")
        i <- which(i)
    }
    if (any(i < 0)) {
        if (all(i < 0))
            i <- seq_along(x)[i]
        else stop("Mixing positive and negative indices is not supported.")
    }
    .extractSamples(x, i, newx = x)
})

#' @rdname MsExperiment
#'
#' @importMethodsFrom Spectra selectSpectraVariables
#'
#' @importMethodsFrom Spectra spectraVariables
#'
#' @importMethodsFrom Spectra peaksVariables
#'
#' @importMethodsFrom ProtGenerics filterSpectra
#'
#' @export
setMethod(
    "filterSpectra", c("MsExperiment", "function"),
    function(object, filter, ...) {
        ls <- length(spectra(object))
        if (!ls)
            return(object)
        have_links <- length(.sample_data_links(object, "spectra")) > 0
        if (have_links)
            object@spectra$._SPECTRA_IDX <- seq_len(ls)
        object@spectra <- filter(object@spectra, ...)
        if (have_links) {
            if (ls != length(spectra(object)))
                object <- .update_sample_data_links_spectra(object)
            svs <- unique(c(spectraVariables(spectra(object)),
                            peaksVariables(spectra(object))))
            object@spectra <- selectSpectraVariables(
                object@spectra, svs[svs != "._SPECTRA_IDX"])
        }
        object
    })
