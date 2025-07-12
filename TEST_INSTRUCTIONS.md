# 🧪 Yunorix SceneKit System - Test Instructions

## 🚀 So testest du das neue 3D System:

### 1. Projekt öffnen und builden
```bash
# In Xcode:
1. Öffne "Yunorix – Reborn Beyond the Nexus.xcodeproj"
2. Wähle "Yunorix – Reborn Beyond the Nexus iOS" Scheme
3. Wähle iPhone 16 Simulator (oder anderes verfügbares Gerät)
4. Drücke ⌘+R (Run)
```

### 2. Was du sehen solltest:

#### ✅ Beim Start:
- **3D Welt**: 20x20 Meter große grüne Ebene
- **Bäume**: Automatisch verteilte Bäume (oder bunte Fallback-Objekte)
- **Pfade**: Braune Kreuzpfade durch die Welt
- **Spieler**: Blauer Charakter im Zentrum (Mage)
- **Gegner**: 3 rote Charaktere um den Spieler herum
- **UI**: Overlay mit Gesundheitsbalken, Buttons, Message Log

#### ✅ UI Elemente:
- **Links oben**: Spieler-Statistiken (HP/MP Balken)
- **Rechts oben**: Ziel-Information (wenn ausgewählt)
- **Links unten**: Bewegungspfeile (↑←↓→)
- **Rechts unten**: Action Buttons (Angriff, Verteidigung, Zauber, etc.)
- **Unten mitte**: Nachrichten-Log

### 3. Steuerung testen:

#### 📱 Touch Controls (iOS):
```
✅ TIPPEN: Auf Boden → Spieler bewegt sich
✅ TIPPEN: Auf Charakter → Charakter auswählen
✅ LONG PRESS: Auf Gegner → Angriff
✅ PAN: Kamera drehen
✅ PINCH: Zoom in/out
✅ UI BUTTONS: Aktionen ausführen
```

#### ⌨️ Keyboard (macOS):
```
✅ WASD: Spieler bewegen
✅ SPACE: Warten
✅ MAUS KLICK: Ziele auswählen
```

### 4. Features testen:

#### 🎮 Grundfunktionen:
1. **Bewegung**: Tippe auf verschiedene Stellen → Spieler läuft hin
2. **Gegner auswählen**: Tippe auf roten Gegner → Wird mit gelbem Ring markiert
3. **Angriff**: Drücke "⚔️ Attack" Button → Kampfanimation
4. **Zauber**: Drücke "✨ Spells" → Zaubermenü öffnet sich
5. **Kamera**: Pan-Gesten → Kamera dreht sich um Spieler

#### 🔍 Debug Features:
1. **Debug Info**: Doppel-tippe die Szene → Debug Overlay
2. **System Status**: Zeigt Spieler-Position, Gegner-Anzahl, etc.
3. **Performance**: FPS Counter in der Ecke

### 5. Was du testen solltest:

#### ✅ Basis-Gameplay:
- [ ] Spieler bewegt sich flüssig
- [ ] Kamera folgt dem Spieler
- [ ] UI reagiert auf Aktionen
- [ ] Gesundheits-/Mana-Balken aktualisieren sich
- [ ] Nachrichten erscheinen im Log

#### ✅ Kampfsystem:
- [ ] Charaktere können ausgewählt werden
- [ ] Angriffs-Animationen funktionieren
- [ ] Schadens-Berechnungen korrekt
- [ ] Gesundheitsbalken aktualisieren sich bei Schäden

#### ✅ Spell System:
- [ ] Zauber-Menü öffnet sich
- [ ] Verschiedene Zauber verfügbar
- [ ] Mana wird verbraucht
- [ ] Heilzauber funktionieren

#### ✅ Performance:
- [ ] Flüssige 60 FPS
- [ ] Keine Ruckler beim Bewegen
- [ ] UI reagiert sofort
- [ ] Memory-Verbrauch stabil

### 6. Häufige Probleme & Lösungen:

#### 🚨 "Keine Assets sichtbar":
```
Problem: Nur bunte Würfel statt 3D-Modelle
Lösung: Normal! Fallback-Assets funktionieren
Verbesserung: FBX-Dateien in "grafic objekts/" legen
```

#### 🚨 "UI nicht sichtbar":
```
Problem: Keine Buttons/Balken
Lösung: Prüfe ob GameView lädt
Debug: Doppel-tippe für Debug Info
```

#### 🚨 "Touch funktioniert nicht":
```
Problem: Keine Reaktion auf Tippen
Lösung: Simulator neustarten
Alternative: macOS verwenden mit Maus
```

#### 🚨 "Crashes beim Start":
```
Problem: App stürzt ab
Lösung: In Xcode Console nach Fehlern schauen
Debug: Breakpoint in viewDidLoad setzen
```

### 7. Erweiterte Tests:

#### 🔬 Performance Test:
1. Öffne "Debug Navigator" in Xcode
2. Starte "Energy Impact" Profiling
3. Bewege Spieler durch die Welt
4. Prüfe Memory/CPU Verbrauch

#### 🔬 Asset Test:
1. Lege eigene FBX-Datei in "grafic objekts/nature-kit/Models/FBX format/"
2. Benenne sie "tree_test.fbx"
3. Füge in AssetManager.swift hinzu:
```swift
GameAsset(name: "tree_test", category: .nature, type: .tree(.defaultTree), 
          path: "nature-kit/Models/FBX format/tree_test.fbx", scale: 3.0)
```
4. Restart → Sollte dein 3D-Modell laden

### 8. Test-Ergebnisse dokumentieren:

```
✅ FUNKTIONIERT:
- [ ] 3D Welt lädt
- [ ] Spieler beweglich  
- [ ] UI sichtbar
- [ ] Touch-Controls
- [ ] Kampfsystem
- [ ] Performance gut

❌ PROBLEME:
- [ ] Beschreibe hier alle Probleme
- [ ] Screenshots bei Bedarf
- [ ] Console-Logs kopieren
```

### 9. Quick Tests (5 Minuten):

1. **App starten** → Sollte 3D Welt zeigen ✅
2. **Auf Boden tippen** → Spieler bewegt sich ✅  
3. **Gegner antippen** → Gelber Ring erscheint ✅
4. **Attack Button** → Kampfanimation ✅
5. **Kamera pan** → Kamera dreht sich ✅

Wenn alle 5 Tests ✅ sind: **System funktioniert perfekt!**

### 10. Bei Problemen:

1. **Xcode Console** checken für Fehlermeldungen
2. **iPhone/iPad echtes Gerät** testen (manchmal besser als Simulator)
3. **macOS Version** testen (hat Keyboard-Controls)
4. **Debug Menu** verwenden (siehe GameViewController)

---

**Erwartung**: Das System sollte sofort funktionieren und eine spielbare 3D-RPG-Welt bieten! 🎮