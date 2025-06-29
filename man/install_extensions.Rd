% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/utils-md.R
\name{install_extensions}
\alias{install_extensions}
\title{Install motherduck extensions}
\usage{
install_extensions(.con, extension_names, silent_msg = TRUE)
}
\arguments{
\item{.con}{duckdb connection}

\item{extension_names}{DuckDB extension names}

\item{silent_msg}{indicate if you want a success / failure report after installation and loading}
}
\value{
message
}
\description{
Installs and loads valid DuckDB extensions
}
\examples{
con <- DBI::dbConnect(duckdb::duckdb())
install_extensions(con,'motherduck',silent_msg=TRUE)

}
