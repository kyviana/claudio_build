"""
Claudio Bot - HP/Chakra Bar Overlay
Barra de HP e Chakra estilizada por cima do NTO
"""

import sys
import json
import math
from pathlib import Path
from PyQt5.QtWidgets import QApplication, QWidget
from PyQt5.QtCore import Qt, QTimer, QRect, QPoint, QRectF, QPropertyAnimation, QEasingCurve
from PyQt5.QtGui import (QPainter, QColor, QLinearGradient, QRadialGradient,
                          QFont, QPen, QBrush, QPainterPath, QFontMetrics)

BOT_STATE_FILE = r"C:\Users\imkvnx\AppData\Roaming\NTOUltimate\ntoultimate updated25\bot\claudio build\storage\state.json"

# ── palette ──────────────────────────────────────────────────────────────────
BG          = QColor(8, 8, 12, 220)
BG_BAR      = QColor(18, 18, 24, 255)
BORDER      = QColor(45, 45, 60, 180)

HP_HIGH     = QColor(220, 60,  40)   # vermelho vivo
HP_MID      = QColor(230, 130, 20)   # laranja
HP_LOW      = QColor(200, 30,  30)   # vermelho escuro pulsante

CK_HIGH     = QColor(40,  140, 220)  # azul elétrico
CK_MID      = QColor(80,  80,  200)  # azul roxo
CK_LOW      = QColor(120, 30,  180)  # roxo

GLOW_HP     = QColor(220, 60,  40,  60)
GLOW_CK     = QColor(40,  140, 220, 60)

TEXT_MAIN   = QColor(230, 230, 240)
TEXT_DIM    = QColor(100, 100, 120)
TEXT_LABEL  = QColor(160, 160, 180)
# ─────────────────────────────────────────────────────────────────────────────


def lerp_color(c1: QColor, c2: QColor, t: float) -> QColor:
    t = max(0.0, min(1.0, t))
    return QColor(
        int(c1.red()   + (c2.red()   - c1.red())   * t),
        int(c1.green() + (c2.green() - c1.green()) * t),
        int(c1.blue()  + (c2.blue()  - c1.blue())  * t),
    )


def bar_color(pct: float, c_high, c_mid, c_low) -> QColor:
    if pct > 0.5:
        return lerp_color(c_mid, c_high, (pct - 0.5) * 2)
    else:
        return lerp_color(c_low, c_mid, pct * 2)


class StatBar(QWidget):
    """Uma barra de stat (HP ou Chakra) com glow e animação."""

    def __init__(self, label: str, color_high, color_mid, color_low, glow_color,
                 icon_char: str, parent=None):
        super().__init__(parent)
        self.label      = label
        self.icon_char  = icon_char
        self.c_high     = color_high
        self.c_mid      = color_mid
        self.c_low      = color_low
        self.glow_color = glow_color

        self._pct       = 1.0   # 0–1 valor real
        self._draw_pct  = 1.0   # animado suavemente
        self._tick      = 0

        self.setFixedHeight(34)

    def set_pct(self, pct: float):
        self._pct = max(0.0, min(1.0, pct))

    def tick(self):
        """Chame a cada frame do timer pra suavizar a animação."""
        diff = self._pct - self._draw_pct
        self._draw_pct += diff * 0.15
        self._tick += 1
        self.update()

    def paintEvent(self, event):
        p = QPainter(self)
        p.setRenderHint(QPainter.Antialiasing)
        W, H = self.width(), self.height()
        pct  = self._draw_pct
        col  = bar_color(pct, self.c_high, self.c_mid, self.c_low)

        BAR_H    = 10
        BAR_Y    = H - BAR_H - 2
        ICON_W   = 22
        BAR_X    = ICON_W + 6
        BAR_W    = W - BAR_X - 2

        # ── fundo da barra ───────────────────────────────────────────────────
        p.setPen(Qt.NoPen)
        p.setBrush(QBrush(BG_BAR))
        path = QPainterPath()
        path.addRoundedRect(QRectF(BAR_X, BAR_Y, BAR_W, BAR_H), 4, 4)
        p.drawPath(path)

        # ── fill animado ─────────────────────────────────────────────────────
        fill_w = max(6, int(BAR_W * pct))
        grad = QLinearGradient(BAR_X, 0, BAR_X + fill_w, 0)
        bright = QColor(min(col.red()+40, 255),
                        min(col.green()+40, 255),
                        min(col.blue()+40, 255))
        grad.setColorAt(0.0, col)
        grad.setColorAt(0.5, bright)
        grad.setColorAt(1.0, col)
        p.setBrush(QBrush(grad))
        fill_path = QPainterPath()
        fill_path.addRoundedRect(QRectF(BAR_X, BAR_Y, fill_w, BAR_H), 4, 4)
        p.drawPath(fill_path)

        # ── glow quando baixo ─────────────────────────────────────────────────
        if pct < 0.35:
            pulse = 0.5 + 0.5 * math.sin(self._tick * 0.18)
            glow = QColor(self.glow_color)
            glow.setAlpha(int(40 + 80 * pulse))
            p.setBrush(QBrush(glow))
            p.setPen(Qt.NoPen)
            glow_path = QPainterPath()
            glow_path.addRoundedRect(
                QRectF(BAR_X - 3, BAR_Y - 3, fill_w + 6, BAR_H + 6), 6, 6)
            p.drawPath(glow_path)

        # ── shine (reflexo no topo) ───────────────────────────────────────────
        shine = QLinearGradient(BAR_X, BAR_Y, BAR_X, BAR_Y + BAR_H // 2)
        shine.setColorAt(0, QColor(255, 255, 255, 35))
        shine.setColorAt(1, QColor(255, 255, 255, 0))
        p.setBrush(QBrush(shine))
        p.drawPath(fill_path)

        # ── ícone ─────────────────────────────────────────────────────────────
        font_icon = QFont("Segoe UI Symbol", 13)
        p.setFont(font_icon)
        p.setPen(col)
        p.drawText(QRect(0, 0, ICON_W, H - BAR_H - 2), Qt.AlignCenter, self.icon_char)

        # ── label ─────────────────────────────────────────────────────────────
        font_lbl = QFont("Consolas", 7)
        font_lbl.setLetterSpacing(QFont.AbsoluteSpacing, 1.5)
        p.setFont(font_lbl)
        p.setPen(TEXT_LABEL)
        p.drawText(QRect(BAR_X, 2, 40, 14), Qt.AlignLeft | Qt.AlignVCenter,
                   self.label)

        # ── valor numérico ────────────────────────────────────────────────────
        pct_str = f"{int(pct * 100)}%"
        font_val = QFont("Consolas", 8, QFont.Bold)
        p.setFont(font_val)
        p.setPen(TEXT_MAIN if pct > 0.35 else col)
        p.drawText(QRect(BAR_X, 2, BAR_W, 14),
                   Qt.AlignRight | Qt.AlignVCenter, pct_str)

        p.end()


class Nameplate(QWidget):
    """Mostra nome + nível do personagem."""

    def __init__(self, parent=None):
        super().__init__(parent)
        self.char_name = "—"
        self.char_level = ""
        self.setFixedHeight(22)

    def set_info(self, name: str, level):
        self.char_name  = name or "—"
        self.char_level = f"Lv {level}" if level else ""
        self.update()

    def paintEvent(self, event):
        p = QPainter(self)
        p.setRenderHint(QPainter.Antialiasing)
        W, H = self.width(), self.height()

        # linha decorativa esquerda
        grad = QLinearGradient(0, H // 2, 30, H // 2)
        grad.setColorAt(0, QColor(80, 80, 120, 0))
        grad.setColorAt(1, QColor(80, 80, 140, 180))
        p.setPen(QPen(QBrush(grad), 1))
        p.drawLine(0, H // 2, 28, H // 2)

        # nome
        font = QFont("Consolas", 9, QFont.Bold)
        font.setLetterSpacing(QFont.AbsoluteSpacing, 0.8)
        p.setFont(font)
        p.setPen(TEXT_MAIN)
        p.drawText(QRect(32, 0, W - 80, H),
                   Qt.AlignLeft | Qt.AlignVCenter, self.char_name)

        # level
        font2 = QFont("Consolas", 7)
        p.setFont(font2)
        p.setPen(TEXT_DIM)
        p.drawText(QRect(0, 0, W - 4, H),
                   Qt.AlignRight | Qt.AlignVCenter, self.char_level)

        # linha decorativa direita
        grad2 = QLinearGradient(W - 30, H // 2, W, H // 2)
        grad2.setColorAt(0, QColor(80, 80, 140, 180))
        grad2.setColorAt(1, QColor(80, 80, 120, 0))
        p.setPen(QPen(QBrush(grad2), 1))
        p.drawLine(W - 60, H // 2, W, H // 2)

        p.end()


class HpChakraOverlay(QWidget):
    def __init__(self):
        super().__init__()
        self.setWindowFlags(
            Qt.FramelessWindowHint |
            Qt.WindowStaysOnTopHint |
            Qt.Tool
        )
        self.setAttribute(Qt.WA_TranslucentBackground)
        self.setFixedSize(260, 110)
        self._drag_pos = None

        # Widgets
        self.nameplate = Nameplate(self)
        self.nameplate.setGeometry(8, 8, 244, 22)

        self.hp_bar = StatBar("HP", HP_HIGH, HP_MID, HP_LOW, GLOW_HP, "♥", self)
        self.hp_bar.setGeometry(8, 34, 244, 34)

        self.ck_bar = StatBar("CK", CK_HIGH, CK_MID, CK_LOW, GLOW_CK, "◈", self)
        self.ck_bar.setGeometry(8, 70, 244, 34)

        # Timer de atualização
        self.timer = QTimer()
        self.timer.timeout.connect(self._tick)
        self.timer.start(33)  # ~30fps

        self._frame = 0
        self._state = {}

        # Posição inicial
        screen = QApplication.primaryScreen().geometry()
        self.move(screen.width() // 2 - 130, screen.height() - 160)

    def _tick(self):
        self._frame += 1
        # Lê state.json a cada ~10 frames (~330ms)
        if self._frame % 10 == 0:
            self._read_state()
        self.hp_bar.tick()
        self.ck_bar.tick()

    def _read_state(self):
        try:
            path = Path(BOT_STATE_FILE)
            if not path.exists():
                return
            with open(path, encoding="utf-8") as f:
                s = json.load(f)
            self._state = s
            self.hp_bar.set_pct(s.get("hp", 100) / 100)
            self.ck_bar.set_pct(s.get("chakra", 100) / 100)
            self.nameplate.set_info(s.get("char", ""), s.get("level", ""))
        except Exception:
            pass

    def paintEvent(self, event):
        p = QPainter(self)
        p.setRenderHint(QPainter.Antialiasing)
        W, H = self.width(), self.height()

        # fundo principal
        p.setBrush(QBrush(BG))
        p.setPen(QPen(BORDER, 1))
        path = QPainterPath()
        path.addRoundedRect(QRectF(0, 0, W, H), 10, 10)
        p.drawPath(path)

        # linha de destaque no topo
        top_grad = QLinearGradient(0, 0, W, 0)
        top_grad.setColorAt(0,   QColor(60, 60, 100, 0))
        top_grad.setColorAt(0.3, QColor(80, 80, 160, 180))
        top_grad.setColorAt(0.7, QColor(80, 80, 160, 180))
        top_grad.setColorAt(1,   QColor(60, 60, 100, 0))
        p.setPen(QPen(QBrush(top_grad), 1.5))
        p.drawLine(10, 1, W - 10, 1)

        p.end()

    def mousePressEvent(self, e):
        if e.button() == Qt.LeftButton:
            self._drag_pos = e.globalPos() - self.frameGeometry().topLeft()

    def mouseMoveEvent(self, e):
        if e.buttons() == Qt.LeftButton and self._drag_pos:
            self.move(e.globalPos() - self._drag_pos)

    def mouseReleaseEvent(self, e):
        self._drag_pos = None

    def mouseDoubleClickEvent(self, e):
        self.close()


if __name__ == "__main__":
    app = QApplication(sys.argv)
    w = HpChakraOverlay()

    w.show()
    sys.exit(app.exec_())
