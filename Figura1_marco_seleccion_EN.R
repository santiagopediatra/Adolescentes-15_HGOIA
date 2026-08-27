## Figure 1: selection framework and analytic samples (US academic English).
library(ragg)

out_path <- "manuscript/media/media/image1.png"
agg_png(out_path, width = 1800, height = 1450, units = "px", res = 150,
        background = "white")
par(mar = c(0, 0, 0, 0), family = "sans", xaxs = "i", yaxs = "i")
plot.new(); plot.window(xlim = c(0, 180), ylim = c(0, 145))

navy <- "#18344F"; edge <- "#34495E"; muted <- "#64748B"
box <- function(x1, y1, x2, y2, fill, lty = 1, radius = 0.02) {
  symbols((x1+x2)/2, (y1+y2)/2, rectangles = matrix(c(x2-x1, y2-y1), 1),
          inches = FALSE, add = TRUE, bg = fill, fg = edge, lwd = 2.2, lty = lty)
}
txt <- function(x, y, label, cex = 1, font = 1, col = "#263746")
  text(x, y, label, cex = cex, font = font, col = col)
arr <- function(x0,y0,x1,y1,lty=1) arrows(x0,y0,x1,y1,length=.14,lwd=2.5,col=edge,lty=lty)

txt(90, 141, "Selection Framework and Analytic Samples", 1.55, 2, navy)
box(42, 122, 138, 137, "#F8FAFC", 2)
txt(90, 133, "Institutional context not directly observed", 1.12, 2, navy)
txt(90, 129, "All deliveries among adolescents 10–19 years old at HGOIA", .98)
txt(90, 125.5, "The study lacked the institutional denominator and data on nonincluded deliveries", .85, 3, muted)

box(7, 72, 62, 116, "#FFF9F2")
text(11, 112, "Potential determinants of selection", adj=c(0,.5), cex=1.02, font=2, col=navy)
text(11, 107, "Sociodemographic factors", adj=c(0,.5), cex=1.02, font=2, col=navy)
text(13, 103, "• maternal age/age group\n• ethnicity and stable partnership\n• education/school delay",
     adj=c(0,1), cex=.78, col="#263746")
text(11, 91.5, "Reproductive/obstetric factors", adj=c(0,.5), cex=1.02, font=2, col=navy)
text(13, 87.5, "• planned pregnancy and reproductive history\n• obstetric/perinatal conditions",
     adj=c(0,1), cex=.78, col="#263746")
text(11, 79.5, "Prenatal care", adj=c(0,.5), cex=1.02, font=2, col=navy)
text(13, 76, "• adequacy and number of visits", adj=c(0,1), cex=.82, col="#263746")

arr(90,122,90,115); box(68,100,114,115,"#FFD8A8")
txt(91, 110.5, "Probability of neonatal admission", .92, 2, navy)
txt(90, 106.5, "and inclusion in the SIP data set", .95)
txt(90, 102.8, "mechanism operating before data availability", .82, 3, muted)
arr(62,98,68,107,2)

arr(101,100,106,93)
box(65,76,157,93,"#DCEBFA")
txt(111, 88.8, "SIP DATA SET AVAILABLE FOR THIS STUDY", 1.04, 2, navy)
txt(111, 84.8, "Records of adolescents aged 10–19 years whose newborns", .91)
txt(111, 81.4, "had been admitted to the neonatal unit (January 2009–June 2024)", .91)
txt(111, 78.2, "7,202 initial mother–newborn records", 1.02, 2, navy)

arr(111,76,111,69)
box(65,53,157,69,"#E8EEF5")
txt(111, 64.7, "Data cleaning and consolidation at the maternal level", 1.02, 2, navy)
txt(111, 60.4, "15 exact duplicate records removed", .92)
txt(111, 56.8, "Linkage and consolidation of multiple-gestation records", .92)

arr(111,53,111,47)
box(65,34,157,47,"#BCD8F7")
txt(111, 42.7, "Final maternal sample", 1.08, 2, navy)
txt(111, 38.6, "7,035 maternal obstetric events", .98)

arr(97,34,61,27); arr(125,34,133,27)
box(24,11,89,27,"#F1F6FC"); box(103,11,166,27,"#EFFBF4")
txt(56.5,22.5,"Within-sample maternal comparisons",1.02,2,navy)
txt(56.5,18.5,"10–14 vs 15–19 years old",.92)
txt(56.5,14.5,"Inference restricted to the selected population",.76,col=muted)
txt(134.5,22.5,"Descriptive neonatal subsample",1.02,2,navy)
txt(134.5,18.5,"6,790 singleton births",.92)
txt(134.5,14.5,"Excludes 245 multiple gestations",.78,col=muted)
txt(90,5.5,"Conceptual diagram: dashed arrows do not represent estimated causal effects.",.82,3,muted)

invisible(dev.off())
cat("Figure 1 regenerated at", out_path, "\n")
