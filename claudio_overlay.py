"""
Claudio Bot Overlay v4
- Barras sem fundo (transparentes)
- Tema preto e branco
- Stats maior e mais bonito
- Buff status corrigido
- Nameplate com gradiente
"""

import sys, json, math
from pathlib import Path
from PyQt5.QtWidgets import QApplication, QWidget, QMenu, QAction
from PyQt5.QtCore import Qt, QTimer, QRectF, QRect
from PyQt5.QtGui import (QPainter, QColor, QLinearGradient, QPen,
                          QBrush, QPainterPath, QFont)

BOT_DIR    = r"C:\Users\imkvnx\AppData\Roaming\NTOUltimate\ntoultimate updated25\bot\claudio build\storage"
STATE_FILE = BOT_DIR + r"\state.json"
POS_FILE   = BOT_DIR + r"\overlay_v4_positions.json"
VIS_FILE   = BOT_DIR + r"\overlay_v4_visibility.json"

HP_CRIT  = 30

# ── PALETA PRETO E BRANCO + ACCENTS ──────────────────────────────────────────
HP_HI  = QColor(220, 55,  35)
HP_MID = QColor(230, 130, 20)
HP_LO  = QColor(200, 25,  25)
CK_HI  = QColor(60,  160, 240)
CK_MID = QColor(90,  90,  210)
CK_LO  = QColor(140, 35,  200)
GLOW_HP= QColor(220, 55,  35, 55)
GLOW_CK= QColor(60,  160, 240, 55)

WHITE  = QColor(240, 240, 240)
LGRAY  = QColor(180, 180, 180)
MGRAY  = QColor(110, 110, 110)
DGRAY  = QColor(50,  50,  50)
BLACK  = QColor(8,   8,   10)
WARN   = QColor(255, 200, 50)
ERR    = QColor(255, 55,  55)
OK     = QColor(200, 200, 200)  # branco suave pro "ok"

def lerp(c1, c2, t):
    t = max(0., min(1., t))
    return QColor(int(c1.red()+(c2.red()-c1.red())*t),
                  int(c1.green()+(c2.green()-c1.green())*t),
                  int(c1.blue()+(c2.blue()-c1.blue())*t))

def bar_col(pct, hi, mid, lo):
    return lerp(mid, hi, (pct-.5)*2) if pct > .5 else lerp(lo, mid, pct*2)

# ── STATE ─────────────────────────────────────────────────────────────────────
_state = {}
_widgets = []
_positions = {}
_visible = {}

def read_state():
    global _state
    try:
        p = Path(STATE_FILE)
        if p.exists():
            with open(p, encoding="utf-8") as f:
                _state = json.load(f)
    except Exception:
        pass

def save_positions():
    try:
        with open(POS_FILE, "w") as f:
            json.dump({w.key: {"x": w.x(), "y": w.y()} for w in _widgets}, f)
    except Exception:
        pass

def load_positions():
    global _positions
    try:
        if Path(POS_FILE).exists():
            with open(POS_FILE) as f:
                _positions = json.load(f)
    except Exception:
        _positions = {}

def save_visibility():
    try:
        with open(VIS_FILE, "w") as f:
            json.dump({w.key: w.isVisible() for w in _widgets}, f)
    except Exception:
        pass

def load_visibility():
    global _visible
    try:
        if Path(VIS_FILE).exists():
            with open(VIS_FILE) as f:
                _visible = json.load(f)
    except Exception:
        _visible = {}

# ── BASE ──────────────────────────────────────────────────────────────────────
class DragWidget(QWidget):
    def __init__(self, key, default_pos):
        super().__init__()
        self.key = key
        self._drag = None
        self.setWindowFlags(Qt.FramelessWindowHint | Qt.WindowStaysOnTopHint | Qt.Tool)
        self.setAttribute(Qt.WA_TranslucentBackground)
        if key in _positions:
            self.move(_positions[key]["x"], _positions[key]["y"])
        else:
            self.move(*default_pos)
        if key in _visible and not _visible[key]:
            self.hide()

    def mousePressEvent(self, e):
        if e.button() == Qt.LeftButton:
            self._drag = e.globalPos() - self.frameGeometry().topLeft()

    def mouseMoveEvent(self, e):
        if e.buttons() == Qt.LeftButton and self._drag:
            self.move(e.globalPos() - self._drag)

    def mouseReleaseEvent(self, e):
        if e.button() == Qt.LeftButton:
            self._drag = None
            save_positions()

    def contextMenuEvent(self, e):
        menu = QMenu(self)
        menu.setStyleSheet(
            "QMenu{background:#111;color:#ccc;border:1px solid #333;font-size:11px;}"
            "QMenu::item{padding:5px 18px;}"
            "QMenu::item:selected{background:#222;}")
        menu.addAction("Esconder este widget", lambda: (self.hide(), save_visibility()))
        menu.addSeparator()
        menu.addAction("Mostrar todos", lambda: [w.show() or save_visibility() for w in _widgets])
        menu.addSeparator()
        menu.addAction("Fechar overlay", QApplication.quit)
        menu.exec_(e.globalPos())

    def update_state(self): pass
    def animate(self): pass

# ── BARRAS HP/CK — sem fundo ──────────────────────────────────────────────────
class BarsWidget(DragWidget):
    W, H = 260, 68

    def __init__(self, default_pos):
        super().__init__("bars", default_pos)
        self.setFixedSize(self.W, self.H)
        self._hp = self._dhp = 1.0
        self._ck = self._dck = 1.0
        self._tick = 0
        self._crit_flash = 0

    def update_state(self):
        new_hp = _state.get("hp", 100) / 100
        if new_hp <= HP_CRIT/100 and self._hp > HP_CRIT/100:
            self._crit_flash = 25
        self._hp = new_hp
        self._ck = _state.get("chakra", 100) / 100

    def animate(self):
        self._dhp += (self._hp - self._dhp) * 0.13
        self._dck += (self._ck - self._dck) * 0.13
        self._tick += 1
        if self._crit_flash > 0: self._crit_flash -= 1
        self.update()

    def _bar(self, p, x, y, w, h, pct, c_hi, c_mid, c_lo, glow, icon):
        col = bar_col(pct, c_hi, c_mid, c_lo)
        IX = 24; BX = x+IX; BW = w-IX

        # trilho
        p.setPen(Qt.NoPen)
        p.setBrush(QColor(20,20,28,210))
        tp = QPainterPath(); tp.addRoundedRect(QRectF(BX,y,BW,h),5,5)
        p.drawPath(tp)

        # fill
        fw = max(8, int(BW*pct))
        g = QLinearGradient(BX,0,BX+fw,0)
        br = QColor(min(col.red()+60,255),min(col.green()+60,255),min(col.blue()+60,255))
        g.setColorAt(0,col); g.setColorAt(.45,br); g.setColorAt(1,col)
        p.setBrush(QBrush(g))
        fp = QPainterPath(); fp.addRoundedRect(QRectF(BX,y,fw,h),5,5)
        p.drawPath(fp)

        # shine
        sh = QLinearGradient(0,y,0,y+h//2)
        sh.setColorAt(0,QColor(255,255,255,35)); sh.setColorAt(1,QColor(255,255,255,0))
        p.setBrush(QBrush(sh)); p.drawPath(fp)

        # glow crítico
        if pct < .35:
            pulse = .5+.5*math.sin(self._tick*.22)
            gc = QColor(glow); gc.setAlpha(int(30+80*pulse))
            p.setBrush(gc); p.setPen(Qt.NoPen)
            gp = QPainterPath(); gp.addRoundedRect(QRectF(BX-4,y-3,fw+8,h+6),7,7)
            p.drawPath(gp)

        # ícone
        fi = QFont("Segoe UI Symbol",13); p.setFont(fi); p.setPen(col)
        p.drawText(QRect(x,y-2,IX,h+4),Qt.AlignCenter,icon)

        # valor %
        fv = QFont("Consolas",9,QFont.Bold); p.setFont(fv)
        p.setPen(WHITE if pct>.35 else col)
        p.drawText(QRect(BX,y,BW-3,h),Qt.AlignRight|Qt.AlignVCenter,f"{int(pct*100)}%")

    def paintEvent(self, ev):
        p = QPainter(self); p.setRenderHint(QPainter.Antialiasing)
        W, H = self.W, self.H

        # borda crítica
        if self._crit_flash > 0 or self._hp <= HP_CRIT/100:
            a = int(200*self._crit_flash/25) if self._crit_flash > 0 else int(100+80*math.sin(self._tick*.25))
            p.setPen(QPen(QColor(220,30,30,a),2)); p.setBrush(Qt.NoBrush)
            p.drawRoundedRect(QRectF(1,1,W-2,H-2),8,8)

        self._bar(p, 0, 6,  W, 26, self._dhp, HP_HI,HP_MID,HP_LO,GLOW_HP,"♥")
        self._bar(p, 0, 38, W, 26, self._dck, CK_HI,CK_MID,CK_LO,GLOW_CK,"◈")
        p.end()

# ── NAMEPLATE ─────────────────────────────────────────────────────────────────
class NameplateWidget(DragWidget):
    W, H = 260, 38

    def __init__(self, default_pos):
        super().__init__("nameplate", default_pos)
        self.setFixedSize(self.W, self.H)
        self._name = "—"; self._level = ""

    def update_state(self):
        self._name  = _state.get("char","—") or "—"
        lv = _state.get("level","")
        self._level = f"Lv {lv}" if lv else ""
        self.update()

    def paintEvent(self, ev):
        p = QPainter(self); p.setRenderHint(QPainter.Antialiasing)
        W, H = self.W, self.H

        # gradiente preto com brilho sutil no centro
        g = QLinearGradient(0,0,W,0)
        g.setColorAt(0,   QColor(5,5,10,220))
        g.setColorAt(0.4, QColor(25,25,35,240))
        g.setColorAt(0.6, QColor(25,25,35,240))
        g.setColorAt(1,   QColor(5,5,10,220))
        p.setPen(Qt.NoPen); p.setBrush(QBrush(g))
        bg = QPainterPath(); bg.addRoundedRect(QRectF(0,0,W,H),10,10)
        p.drawPath(bg)

        # linha fina branca no topo
        tg = QLinearGradient(0,0,W,0)
        tg.setColorAt(0,QColor(255,255,255,0))
        tg.setColorAt(0.3,QColor(255,255,255,80))
        tg.setColorAt(0.7,QColor(255,255,255,80))
        tg.setColorAt(1,QColor(255,255,255,0))
        p.setPen(QPen(QBrush(tg),1)); p.drawLine(12,1,W-12,1)

        # nome em branco bold
        fn = QFont("Consolas",12,QFont.Bold)
        p.setFont(fn); p.setPen(WHITE)
        p.drawText(QRect(12,0,W-80,H),Qt.AlignLeft|Qt.AlignVCenter,self._name)

        # level em cinza
        fl = QFont("Consolas",9)
        p.setFont(fl); p.setPen(MGRAY)
        p.drawText(QRect(0,0,W-10,H),Qt.AlignRight|Qt.AlignVCenter,self._level)
        p.end()

# ── STATS ─────────────────────────────────────────────────────────────────────
class StatsWidget(DragWidget):
    W, H = 220, 90

    def __init__(self, default_pos):
        super().__init__("stats", default_pos)
        self.setFixedSize(self.W, self.H)
        self._rows = []

    def update_state(self):
        glove = _state.get("glove_taijutsu", 0)
        sword = _state.get("sword_taijutsu", 0)
        dist  = _state.get("distance", 0)
        wpns  = {"Glove Taijutsu": glove, "Sword Taijutsu": sword, "Distance": dist}
        best  = max(wpns, key=wpns.get)
        self._rows = [
            ("Ninjutsu",  _state.get("ninjutsu", 0),  QColor(100,180,255)),
            ("Taijutsu",  _state.get("taijutsu", 0),  QColor(200,200,200)),
            (best,        wpns[best],                   QColor(255,215,80)),
        ]
        self.update()

    def paintEvent(self, ev):
        p = QPainter(self); p.setRenderHint(QPainter.Antialiasing)
        W, H = self.W, self.H

        # fundo preto semi-transparente
        p.setPen(Qt.NoPen)
        p.setBrush(QColor(6,6,10,210))
        bg = QPainterPath(); bg.addRoundedRect(QRectF(0,0,W,H),10,10)
        p.drawPath(bg)

        # linha lateral esquerda colorida por linha
        for i,(lbl,val,col) in enumerate(self._rows):
            y = 8 + i*26

            # barra lateral decorativa
            p.setPen(Qt.NoPen)
            p.setBrush(QColor(col.red(),col.green(),col.blue(),60))
            p.drawRoundedRect(QRectF(0,y+2,3,20),2,2)

            # label
            fl = QFont("Consolas",10); p.setFont(fl); p.setPen(LGRAY)
            p.drawText(QRect(10,y,140,24),Qt.AlignLeft|Qt.AlignVCenter,lbl)

            # valor
            fv = QFont("Consolas",10,QFont.Bold); p.setFont(fv); p.setPen(col)
            p.drawText(QRect(0,y,W-10,24),Qt.AlignRight|Qt.AlignVCenter,str(val))

        p.end()

# ── BUFF STATUS ───────────────────────────────────────────────────────────────
class BuffStatusWidget(DragWidget):
    W, H = 220, 34

    def __init__(self, default_pos):
        super().__init__("buff_status", default_pos)
        self.setFixedSize(self.W, self.H)
        self._label = "?"
        self._col   = MGRAY
        self._tick  = 0

    def update_state(self):
        ml   = _state.get("ml", 0)
        b1   = _state.get("ml_buff1", 0)
        b2   = _state.get("ml_buff2", 0)
        base = _state.get("ml_base", 0)
        if not base or base == 0:
            self._label, self._col = "BUFF: —", MGRAY
        elif b2 and ml >= b2:
            self._label, self._col = "BUFF COMPLETO", OK
        elif b1 and ml >= b1:
            self._label, self._col = "BUFF INCOMPLETO", WARN
        else:
            self._label, self._col = "SEM BUFF", ERR
        self.update()

    def animate(self):
        self._tick += 1

    def paintEvent(self, ev):
        p = QPainter(self); p.setRenderHint(QPainter.Antialiasing)
        W, H = self.W, self.H
        col = self._col

        # fundo escuro
        pulse = .5+.5*math.sin(self._tick*.2)
        bg_alpha = 210
        if self._label == "SEM BUFF":
            bg = QColor(35,6,6,bg_alpha)
        elif self._label == "BUFF INCOMPLETO":
            bg = QColor(30,22,4,bg_alpha)
        else:
            bg = QColor(6,6,10,bg_alpha)
        p.setPen(Qt.NoPen); p.setBrush(bg)
        bp = QPainterPath(); bp.addRoundedRect(QRectF(0,0,W,H),10,10)
        p.drawPath(bp)

        # borda
        border_a = int(80+60*pulse) if self._label != "BUFF COMPLETO" else 60
        p.setPen(QPen(QColor(col.red(),col.green(),col.blue(),border_a),1))
        p.setBrush(Qt.NoBrush)
        p.drawRoundedRect(QRectF(.5,.5,W-1,H-1),10,10)

        # texto
        f = QFont("Consolas",10,QFont.Bold)
        f.setLetterSpacing(QFont.AbsoluteSpacing,1.8)
        p.setFont(f); p.setPen(col)
        p.drawText(QRect(0,0,W,H),Qt.AlignCenter,self._label)
        p.end()

# ── EFEITO HP CRÍTICO ─────────────────────────────────────────────────────────
class CritOverlay(QWidget):
    def __init__(self, screen):
        super().__init__()
        self.setWindowFlags(Qt.FramelessWindowHint|Qt.WindowStaysOnTopHint|
                            Qt.Tool|Qt.WindowTransparentForInput)
        self.setAttribute(Qt.WA_TranslucentBackground)
        self.setAttribute(Qt.WA_TransparentForMouseEvents)
        self.setGeometry(screen)
        self._tick = 0; self._active = False

    def set_active(self, v):
        self._active = v
        if v: self.show()
        else: self.hide()

    def animate(self):
        self._tick += 1
        if self._active: self.update()

    def paintEvent(self, ev):
        if not self._active: return
        p = QPainter(self)
        pulse = .5+.5*math.sin(self._tick*.18)
        W, H = self.width(), self.height()
        # vinheta vermelha nas bordas
        for rect, a in [
            (QRect(0,0,W,90),   int(55*pulse)),
            (QRect(0,H-90,W,90),int(55*pulse)),
            (QRect(0,0,90,H),   int(45*pulse)),
            (QRect(W-90,0,90,H),int(45*pulse)),
        ]:
            p.fillRect(rect, QColor(200,0,0,a))
        p.end()

# ── MULTI CLIENT ─────────────────────────────────────────────────────────────
def focus_critical_window(char_name):
    try:
        import ctypes
        user32 = ctypes.windll.user32
        def cb(hwnd, _):
            if user32.IsWindowVisible(hwnd):
                buf = ctypes.create_unicode_buffer(256)
                user32.GetWindowTextW(hwnd, buf, 256)
                if char_name and char_name.lower() in buf.value.lower():
                    user32.SetForegroundWindow(hwnd)
                    return False
            return True
        ft = ctypes.WINFUNCTYPE(ctypes.c_bool, ctypes.c_int, ctypes.c_int)
        user32.EnumWindows(ft(cb), 0)
    except Exception:
        pass

# ── MAIN ──────────────────────────────────────────────────────────────────────
def main():
    app = QApplication(sys.argv)
    screen = QApplication.primaryScreen().geometry()
    cx = screen.width()//2

    load_positions(); load_visibility()

    nameplate = NameplateWidget((cx-130, 30))
    bars      = BarsWidget     ((cx-130, 72))
    stats     = StatsWidget    ((cx-110, 145))
    buff_st   = BuffStatusWidget((cx-110, 240))
    crit_ov   = CritOverlay(screen)

    _widgets.extend([nameplate, bars, stats, buff_st])
    for w in _widgets: w.show()
    crit_ov.hide()

    _focus_pending = [False]

    def on_read():
        read_state()
        for w in _widgets: w.update_state()
        hp = _state.get("hp", 100)
        crit = hp <= HP_CRIT
        crit_ov.set_active(crit)
        if crit and not _focus_pending[0]:
            _focus_pending[0] = True
            QTimer.singleShot(2000, lambda: (
                focus_critical_window(_state.get("char","")) if _state.get("hp",100) <= HP_CRIT else None,
                _focus_pending.__setitem__(0, False)
            ))
        if not crit: _focus_pending[0] = False

    def on_anim():
        bars.animate()
        buff_st.animate()
        crit_ov.animate()

    QTimer().singleShot(0, lambda: None)  # warmup

    rt = QTimer(); rt.timeout.connect(on_read); rt.start(400)
    at = QTimer(); at.timeout.connect(on_anim); at.start(33)

    sys.exit(app.exec_())

if __name__ == "__main__":
    main()