
# Self-defined formatting function for fixing labels
year_label_formatter <- function(x) {
  x <- gsub('X', '', x)              # Remove leading X if present
}