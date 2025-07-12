# 🚀 Build & Test Guide - Yunorix Open World RPG

## 📋 Vollständige Anleitung zum Starten des Spiels

### 1. **Projekt-Setup in Xcode**

#### Schritt 1: Xcode öffnen
```bash
1. Öffne Xcode (Version 15.0+ erforderlich)
2. Navigiere zu: /Users/4gi.tv/Documents/Yunorix – Reborn Beyond the Nexus/
3. Doppelklick auf: "Yunorix – Reborn Beyond the Nexus.xcodeproj"
```

#### Schritt 2: Build-Konfiguration
```
✅ Target auswählen: "Yunorix – Reborn Beyond the Nexus iOS"
✅ Scheme: "Yunorix – Reborn Beyond the Nexus iOS"  
✅ Device: iPhone 16 Simulator (oder echtes Gerät)
✅ iOS Deployment Target: 17.6+
```

#### Schritt 3: Code Signing beheben
```
1. Projekt auswählen → "Yunorix – Reborn Beyond the Nexus"
2. Targets → "Yunorix – Reborn Beyond the Nexus iOS"
3. Signing & Capabilities Tab
4. Team: Wähle dein Apple Developer Team
   (Oder "Automatically manage signing" aktivieren)
```

### 2. **Fehlende Dependencies hinzufügen**

Das Projekt benötigt diese Frameworks:
```swift
✅ UIKit (bereits hinzugefügt)
✅ SwiftUI (bereits hinzugefügt)  
✅ SceneKit (bereits hinzugefügt)
✅ RealityKit (muss hinzugefügt werden)
✅ GameplayKit (muss hinzugefügt werden)
```

#### RealityKit hinzufügen:
```
1. Projekt auswählen
2. Target → "Build Phases"
3. "Link Binary With Libraries" aufklappen
4. "+" drücken
5. "RealityKit.framework" auswählen → Add
6. "GameplayKit.framework" auswählen → Add
```

### 3. **App Icons hinzufügen** ⚠️ WICHTIG

#### Problem: AppIcon.appiconset ist leer
```
Aktueller Status: Nur Contents.json vorhanden
Benötigt: Icon-Dateien in verschiedenen Größen
```

#### Schnelle Lösung:
```bash
1. Gehe zu: Yunorix – Reborn Beyond the Nexus iOS/Assets.xcassets/AppIcon.appiconset/
2. Erstelle temporäre Icons oder verwende den AppIconGenerator:

# Einfache Lösung: Verwende SF Symbols als temporäre Icons
1. Xcode → Assets.xcassets → AppIcon
2. Rechtsklick → "Import..." 
3. Wähle beliebige PNG-Dateien als temporäre Icons
```

### 4. **Build-Prozess starten**

#### Clean Build (Empfohlen):
```bash
1. Product → Clean Build Folder (⌘+Shift+K)
2. Product → Build (⌘+B)
3. Warte auf Build-Completion
```

#### Bei Build-Fehlern:
```
Häufige Fehler:
❌ "Signing for 'X' requires a development team"
   → Lösung: Code Signing (siehe Schritt 3)

❌ "Cannot find 'Experience' in scope" 
   → Lösung: Reality Composer Projekt erstellen

❌ "Missing import for RealityKit"
   → Lösung: RealityKit Framework hinzufügen
```

### 5. **App starten und testen**

#### Simulator starten:
```bash
1. Target: iPhone 16 Simulator auswählen
2. Product → Run (⌘+R)
3. Simulator öffnet sich automatisch
4. App sollte starten mit Intro-Screen
```

#### Erwarteter Spiel-Flow:
```
✅ 1. Intro Screen (5 Sekunden)
✅ 2. Main Menu erscheint
✅ 3. "New Adventure" → Character Selection
✅ 4. Character auswählen → Tutorial
✅ 5. Tutorial → Open World 3D
```

### 6. **Open World Features testen**

#### Steuerung (iOS Simulator):
```
🎮 Mouse-Drag: Spieler bewegen
🎮 Scroll: Kamera zoom
🎮 Keyboard (wenn aktiviert):
   - WASD: Bewegung
   - Space: Stoppen
```

#### Was du sehen solltest:
```
🌍 50x50 Meter große grüne Welt
🌳 Automatisch platzierte Bäume und Steine
💎 Gelbe Sammel-Objekte (Kristalle) 
👹 Rote Gegner die patrouillieren
🌟 Magische Portale an den Ecken
👤 Blauer Spieler-Charakter im Zentrum
```

#### UI-Overlay:
```
📊 Oben links: Gesundheit/Mana Balken
📍 Oben rechts: Position (X, Z Koordinaten)
💬 Unten: Game Messages
🎮 Unten: Touch-Controls (iOS)
```

### 7. **Gameplay testen**

#### Item Collection:
```
✅ Nähere dich gelben Kristallen
✅ Automatisches Sammeln bei Berührung
✅ Mana erhöht sich um +10
✅ "Collected magical essence!" Message
```

#### Enemy Encounters:
```
✅ Rote Gegner bewegen sich automatisch
✅ Bei Berührung: Gesundheit -0.5
✅ "Enemy encounter!" Message
✅ Bei 0 HP: Game Over Screen
```

#### Exploration:
```
✅ Freie Bewegung in 50x50m Welt
✅ Kamera folgt dem Spieler automatisch
✅ Kollisions-Erkennung mit Weltgrenzen
✅ Smooth Movement und Animationen
```

### 8. **Debug Features**

#### Debug-Informationen aktivieren:
```
1. Im Open World: Doppel-tap auf den Screen
2. Debug Overlay erscheint mit:
   - Current Position
   - Health/Mana Status  
   - Item Count
   - Performance Info
```

#### Console-Output:
```bash
# In Xcode Console solltest du sehen:
🎮 Yunorix - Reborn Beyond the Nexus
📱 Device: iPhone Simulator
📋 iOS Version: 17.6
🎯 Starting Game Flow System...
🎮 GameFlow: Transitioning from intro to mainMenu
🌍 Open world initialized
```

### 9. **Performance Testing**

#### Erwartete Performance:
```
📊 Frame Rate: ~60 FPS
📊 Memory Usage: <200MB
📊 Smooth Animations: Ja
📊 Responsive Controls: <100ms Latenz
```

#### Performance-Probleme beheben:
```
🐌 Niedrige FPS:
   → Reduziere Objekt-Anzahl in OpenWorldController
   → Deaktiviere Schatten in setupLighting()

💾 Hoher Memory-Verbrauch:
   → Prüfe Asset-Loading in AssetManager
   → Deaktiviere Partikel-Effekte temporär
```

### 10. **Häufige Probleme & Lösungen**

#### ❌ "App startet nicht"
```
Lösung:
1. Clean Build Folder
2. Prüfe Code Signing
3. Restart Simulator
4. Prüfe iOS Version (17.6+ erforderlich)
```

#### ❌ "Schwarzer Bildschirm"
```
Lösung:
1. Prüfe Console für Errors
2. Vergewissere dich dass GameFlowView lädt
3. Prüfe SwiftUI Preview in IntroScreen.swift
```

#### ❌ "Controls funktionieren nicht"
```
Lösung (iOS Simulator):
1. Device → Touch ID → Not Enrolled
2. Hardware → Keyboard → Connect Hardware Keyboard
3. Verwende Maus für Touch-Input
```

#### ❌ "3D-Objekte nicht sichtbar"
```
Status: Normal! 
Grund: Fallback-System aktiv
Info: Bunte Würfel = System funktioniert
Todo: Echte 3D-Models in /grafic objekts/ hinzufügen
```

### 11. **Erfolgreiche Test-Completion**

Du weißt, dass alles funktioniert wenn:
```
✅ App startet ohne Crashes
✅ Intro → Main Menu → Character Selection
✅ Open World lädt und zeigt 3D-Umgebung
✅ Spieler-Bewegung funktioniert
✅ Items können gesammelt werden
✅ UI zeigt korrekte Health/Mana/Items
✅ Kamera folgt Spieler smooth
✅ Debug-Info funktioniert
✅ 60 FPS Performance
```

### 12. **Next Steps nach erfolgreichem Test**

```
🎯 Spiel ist voll funktionsfähig!
🎯 Kann erweitert werden mit:
   - Mehr Gegner-Typen
   - Quest-System
   - Inventar-Management
   - Sound/Musik
   - Erweiterte Kampf-Mechaniken
   - Multiplayer-Features
```

---

## 🎮 **SCHNELLSTART (5 Minuten)**

```bash
1. Xcode öffnen → Projekt laden
2. Team in Signing & Capabilities setzen
3. RealityKit Framework hinzufügen
4. ⌘+R (Run)
5. Spielen! 🎮
```

**Wenn du Probleme hast, schaue in die Xcode Console für detaillierte Error-Messages!**