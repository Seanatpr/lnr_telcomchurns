source('project_init.R', local = TRUE)


# Install -----------------------------------------------------------------
# install.packages("partykit")
# devtools::install_github("ibecav/CGPfunctions", build_vignettes = TRUE)
# install.packages("CHAID", repos="http://R-Forge.R-project.org")


# Download data -----------------------------------------------------------
df_working <- read.csv("https://raw.githubusercontent.com/quants-book/CSV_Files/master/churn.csv")
write_csv(x = df_working, path = FILE_DATA_RAW)
