## Figure 3: annual distribution by maternal age group (US academic English).
library(ragg)

years <- 2009:2024
totals <- c(565,570,627,588,622,659,697,602,410,360,255,275,193,207,265,140)
younger <- c(21,22,18,24,32,37,43,32,16,23,12,15,15,22,35,19)
older <- totals - younger
prop_young <- younger/totals
prop_old <- older/totals

out_path <- "manuscript/media/media/image3.jpeg"
agg_jpeg(out_path, width=1600, height=950, units="px", res=150, quality=96,
         background="white")
par(mar=c(7.5,6.2,6.2,15.5), family="sans", xaxs="i", yaxs="i", xpd=NA)
x <- barplot(rbind(prop_young,prop_old), beside=FALSE, col=c("#4A5661","#B7BBC0"),
             border=NA, space=.35, ylim=c(0,1.05), axes=FALSE, xlab="", ylab="")
axis(2, at=seq(0,1,.25), labels=paste0(seq(0,100,25),"%"), las=1,
     col.axis="#455A64", cex.axis=.9)
text(x[1:15], -.09, as.character(2009:2023), col="#455A64", cex=.70)
text(x[16], -.09, "2024\n(Jan–Jun)", col="#A9330A", cex=.70, font=2)
abline(h=seq(.25,1,.25), col="#E5E9EC", lwd=1)
box(bty="l", col="#455A64")
mtext("Delivery year", side=1, line=5, cex=1.05, col="#263746")
mtext("Proportion", side=2, line=4, cex=1.05, col="#263746")
title(main="Annual Distribution by Maternal Age Group", line=3.1, cex.main=1.45,
      col.main="#18344F", font.main=2)
mtext("Proportions within the SIP data set selected based on neonatal admission", side=3,
      line=1.5, cex=1.02, col="#4B5D73")
text(x, 1.025, totals, cex=.82, col="#263746")
text(x, pmax(prop_young/2,.018), younger, cex=.77, col="white", font=2)

orange <- "#E65300"
segments((x[15]+x[16])/2, 0, (x[15]+x[16])/2, 1.05,
         col=orange, lty=2, lwd=2)
rect(x[16]-.36,0,x[16]+.36,1,border=orange,lwd=2)
legend(max(x)+1.15,.82, legend=c("Ages 15–19 years","Ages 10–14 years"),
       fill=c("#B7BBC0","#4A5661"), border=NA, bty="n", cex=.92)
text(max(x)+1.15,.59,"2024: January–June\npartial-year count;\nnot directly comparable\nwith full calendar years",
     adj=c(0,1), col="#A9330A", font=2, cex=.8)
text(max(x)+1.15,.27,"N above each bar:\nmaternal obstetric events",adj=c(0,1),cex=.65)
invisible(dev.off())
cat("Figure 3 regenerated at", out_path, "\n")
