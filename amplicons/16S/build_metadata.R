## build_metadata.R
## Build the amplicon metadata csv from the lab sample database.
## Main sheet gives euro number to site and date. MetaData sheet gives the probe
## data keyed by site and date. Join them on site plus date.
## Rerun this when new samples get added to the database.

library(readxl)

xlsx <- "/home/achrostowski/amplicon_16S_all/Eggleston_Lab_Sample_Database.xlsx"
out <- "/home/achrostowski/amplicon_16S_all/metadata_E400to672.csv"

## Main has two columns both named euro. The sample numbers are in the SECOND
## one. Read positionally, the sheet mixes types so readxl makes everything
## character and the names are useless anyway.
main <- read_excel(xlsx, sheet="Main", col_names=FALSE, skip=1, .name_repair="minimal")
euro <- suppressWarnings(as.integer(as.numeric(main[[2]])))
loc_raw <- as.character(main[[4]])

## Main stores dates as excel serials, MetaData stores them as real dates.
## MUST parse them differently or the join finds nothing.
date_raw <- as.Date(suppressWarnings(as.numeric(main[[12]])), origin="1899-12-30")

## site code is in brackets. the sheet spells Missisquoi both ways so match
## on the bracket code, not the name.
site <- sub("^.*\\((MIS|STA|MAB)\\).*$", "\\1", loc_raw)
site[!site %in% c("MIS","STA","MAB")] <- NA

ok <- !is.na(euro) & euro >= 400 & euro <= 672 & !is.na(site) & !is.na(date_raw)
samples <- data.frame(Sample_Number=euro[ok], Location=site[ok], Date=date_raw[ok])
samples <- samples[order(samples$Sample_Number), ]
cat("samples with site and date:", nrow(samples), "\n")

## probe columns come in as character because NA is typed as text, so coerce
num <- function(x) suppressWarnings(as.numeric(as.character(x)))
md <- read_excel(xlsx, sheet="MetaData", col_names=FALSE, skip=1, .name_repair="minimal")
md <- data.frame(Location=as.character(md[[1]]), Date=as.Date(md[[2]]),
                 Air_temp=num(md[[3]]), Water_temp=num(md[[4]]),
                 DO_1=num(md[[5]]), DO_2=num(md[[6]]), DO_3=num(md[[7]]),
                 SPC=num(md[[8]]), C=num(md[[9]]), SAL=num(md[[10]]), pH=num(md[[11]]),
                 Chl_a=num(md[[12]]), PC=num(md[[13]]), Depth=num(md[[14]]),
                 BV=num(md[[15]]), Q_val=num(md[[16]]),
                 stringsAsFactors=FALSE)
md <- md[!is.na(md$Location) & !is.na(md$Date), ]
cat("probe rows:", nrow(md), "\n")

meta <- merge(samples, md, by=c("Location","Date"), all.x=TRUE)
meta <- meta[order(meta$Sample_Number), ]
cat("joined to probe data:", sum(!is.na(meta$Water_temp)), "of", nrow(meta), "\n")
## Season uses astronomical cuts, not meteorological. Camilla's file has
## 6/20/23 as Spring and 6/25/25 as Summer, so the split is the solstice.
## MUST keep these cuts or the seasons stop matching her published figures.
mmdd <- as.integer(format(meta$Date, "%m")) * 100 + as.integer(format(meta$Date, "%d"))
meta$Season <- ifelse(mmdd >= 1221 | mmdd <= 319, "Winter",
               ifelse(mmdd <= 620, "Spring",
               ifelse(mmdd <= 921, "Summer", "Fall")))

## Bloom phases come straight from Table 2 of Camilla's thesis, page 26.
## Do NOT re-derive these from PC. Her rule was PC above 1 ug/L, but only
## inside the summer window, confirmed against field observation and
## cyanobacterial abundance, and treated as one contiguous bloom per summer.
## So her table has MIS 2023-07-19 as Bloom at 0.97 and MIS 2023-08-23 as Post
## at 0.77. A bare threshold reproduces neither, and applied year round it
## picks up winter probe readings with no cyanobacteria in the sample at all.
tab2 <- data.frame(
  Location = c("MIS","MIS","STA","MIS","MIS","STA","MIS","STA","MIS","STA","STA","MIS","MIS","STA",
               "MIS","MIS","STA","MIS","MIS","STA","MIS","STA"),
  Date = as.Date(c("2023-07-05","2023-07-11","2023-07-19","2023-07-19","2023-07-25","2023-07-25",
                   "2023-08-02","2023-08-02","2023-08-16","2023-08-16","2023-08-23","2023-08-23",
                   "2023-08-29","2023-08-29","2024-07-02","2024-07-16","2024-07-30","2024-07-30",
                   "2024-08-13","2024-08-13","2024-08-21","2024-08-21")),
  BloomPhase = c("Pre","Pre","Pre","Bloom","Bloom","Bloom","Bloom","Bloom","Bloom","Bloom",
                 "Bloom","Post","Post","Post","Pre","Pre","Pre","Bloom","Bloom","Bloom",
                 "Post","Post"),
  stringsAsFactors = FALSE)
meta <- merge(meta, tab2, by=c("Location","Date"), all.x=TRUE)
meta <- meta[order(meta$Sample_Number), ]

## MAB never reached bloom classification by phycocyanin or field observation,
## so every MAB sample outside her table is background, not unknown.
meta$BloomPhase[is.na(meta$BloomPhase) & meta$Location == "MAB"] <- "Non"

## 2025 and 2026 have no phase assignment. Her method needs field observation
## and we do not have it for those samples. Left NA on purpose, Erin's call.
cat("bloom phases assigned\n")
print(table(meta$BloomPhase, format(meta$Date, "%Y"), useNA="ifany"))



## column order matches her file. sample number is the rowname, not a column,
## because 16SpostProcessingCKKS.Rmd reads with row.names=1.
cols <- c("Location","Date","Season","Air_temp","Water_temp","DO_1","DO_2","DO_3",
          "SPC","C","SAL","pH","Chl_a","PC","Depth","BV","Q_val","BloomPhase")
rownames(meta) <- meta$Sample_Number
meta$Date <- format(meta$Date, "%m/%d/%y")
write.csv(meta[, cols], out, na="NA")
cat("wrote", nrow(meta), "rows to", out, "\n")
print(table(meta$Season))
print(table(meta$BloomPhase, useNA="ifany")) 