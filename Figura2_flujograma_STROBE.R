## Regenerates manuscript/media/media/image2.png: STROBE participant
## selection flow diagram (Figure 2 of the manuscript), in academic English.
## Corrige el defecto donde el borde superior del primer recuadro
## atravesaba la primera linea de texto: la altura de cada recuadro se
## calcula a partir del numero real de lineas de su contenido, con
## margen vertical explicito por encima y por debajo del texto.

library(ragg)

out_path <- "manuscript/media/media/image2.png"

W <- 1280
H <- 1100
agg_png(out_path, width = W, height = H, units = "px", res = 150, background = "white")

par(mar = c(0, 0, 0, 0), xaxs = "i", yaxs = "i")
plot.new()
plot.window(xlim = c(0, 160), ylim = c(-45, 95))

## ---- utilidades -----------------------------------------------------

line_h <- 4.6          # alto de linea en unidades de usuario
pad_v  <- 3.0           # margen vertical (arriba y abajo) dentro de cada caja
pad_h  <- 3.0

## Dibuja una caja centrada en (cx, cy_top -> hacia abajo) con texto
## multilinea, calculando la altura exacta segun el numero de lineas.
draw_box <- function(cx, y_top, w, lines, cex = 0.72, font = rep(1, length(lines)),
                      lty = "solid", fill = "white", border_col = "black",
                      bold_lines = NULL) {
  n <- length(lines)
  h <- n * line_h + 2 * pad_v
  y_bottom <- y_top - h
  rect(cx - w / 2, y_bottom, cx + w / 2, y_top,
       lty = lty, col = fill, border = border_col, lwd = 1.4)
  ## primera linea de texto a pad_v + media_linea desde el techo de la caja
  y_text_top <- y_top - pad_v - line_h / 2
  for (i in seq_len(n)) {
    fnt <- if (!is.null(bold_lines) && i %in% bold_lines) 2 else font[i]
    text(cx, y_text_top - (i - 1) * line_h, lines[i], cex = cex, font = fnt)
  }
  list(top = y_top, bottom = y_bottom, left = cx - w / 2, right = cx + w / 2,
       cx = cx, cy = (y_top + y_bottom) / 2)
}

draw_arrow <- function(x0, y0, x1, y1) {
  arrows(x0, y0, x1, y1, length = 0.10, angle = 25, lwd = 1.4, code = 2)
}

## ---- Caja 1: base inicial --------------------------------------------

b1 <- draw_box(
  cx = 42, y_top = 93, w = 78,
  lines = c(
    "Mother–newborn records, Hospital Gineco-Obstétrico",
    "Isidro Ayora (HGOIA) (SIP-CLAP/PAHO), January 2009–June 2024",
    "Aged 10–19 years old",
    "n = 7,202"
  ),
  cex = 0.72,
  bold_lines = 4
)

## Excluidos 1 (dashed) ---------------------------------------------------

e1 <- draw_box(
  cx = 122, y_top = b1$top - 2, w = 68,
  lines = c(
    "Excluded:",
    "- 15 exact duplicate records in the",
    "  raw data set."
  ),
  cex = 0.68, lty = "dashed", fill = "grey88",
  bold_lines = 1
)

## Caja 2: tras exclusion de duplicados ----------------------------------

b2_top <- b1$bottom - 10
b2 <- draw_box(
  cx = 42, y_top = b2_top, w = 78,
  lines = c(
    "Records remaining after removal of exact duplicates",
    "n = 7,187"
  ),
  cex = 0.72, bold_lines = 2
)

## Excluidos 2 (dashed) ---------------------------------------------------

e2 <- draw_box(
  cx = 122, y_top = b2$top - 1, w = 68,
  lines = c(
    "Excluded: 152 records",
    "- Multiple-gestation records consolidated using",
    "  a 13-variable composite linkage key.",
    "- A 3-week gestational-age threshold was applied."
  ),
  cex = 0.68, lty = "dashed", fill = "grey88",
  bold_lines = 1
)

## Caja 3: muestra analitica final ---------------------------------------

b3_top <- b2$bottom - 10
b3 <- draw_box(
  cx = 42, y_top = b3_top, w = 78,
  lines = c(
    "FINAL ANALYTIC SAMPLE",
    "Unit of analysis: maternal obstetric event",
    "n = 7,035"
  ),
  cex = 0.74, bold_lines = c(1, 3)
)

## Cajas finales: subgrupos etarios --------------------------------------

b4_top <- b3$bottom - 10
b4a <- draw_box(
  cx = 20, y_top = b4_top, w = 36,
  lines = c("Aged 10–14 years old", "n = 386 (5.5%)"),
  cex = 0.70
)
b4b <- draw_box(
  cx = 64, y_top = b4_top, w = 36,
  lines = c("Aged 15–19 years old", "n = 6,649 (94.5%)"),
  cex = 0.70
)

## ---- flechas -----------------------------------------------------------

draw_arrow(b1$cx, b1$bottom, b2$cx, b2$top)
draw_arrow(b2$cx, b2$bottom, b3$cx, b3$top)

## Horizontal exclusion arrows connect the actual rectangle boundaries.
## Starting at $right prevents any line segment from appearing inside the
## source boxes; ending at $left places each arrow tip on the target border.
draw_arrow(b1$right, b1$cy, e1$left, b1$cy)
draw_arrow(b2$right, b2$cy, e2$left, b2$cy)

## bifurcacion final: linea vertical corta desde b3, luego a cada caja
mid_y <- b3$bottom - 5
segments(b3$cx, b3$bottom, b3$cx, mid_y, lwd = 1.4)
segments(b4a$cx, mid_y, b4b$cx, mid_y, lwd = 1.4)
draw_arrow(b4a$cx, mid_y, b4a$cx, b4a$top)
draw_arrow(b4b$cx, mid_y, b4b$cx, b4b$top)

## ---- pie de figura -------------------------------------------------------

caption_y <- b4a$bottom - 5.5
text(2, caption_y, "Figure 2. STROBE flow diagram of participant selection.",
     adj = c(0, 1), cex = 0.78, font = 2)

nota <- paste(
  "The 15 duplicate records were rows that were identical across all fields in the raw data set.",
  "The 3-week threshold used to consolidate multiple-gestation records was selected on clinical",
  "grounds (records could not represent the same delivery event); its robustness was assessed in",
  "a sensitivity analysis not shown in this figure.",
  sep = "\n"
)
text(2, caption_y - 4.6, nota, adj = c(0, 1), cex = 0.62, font = 3)

invisible(dev.off())

## Recorta el margen blanco sobrante y deja un borde uniforme pequeño,
## para que el lienzo no incluya el espacio en blanco no utilizado.
library(magick)
im <- image_read(out_path)
im <- image_trim(im, fuzz = 2)
im <- image_border(im, "white", "20x20")
image_write(im, out_path)

cat("Figure 2 regenerated at", out_path, "\n")
