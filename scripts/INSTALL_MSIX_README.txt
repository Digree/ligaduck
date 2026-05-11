================================================
  LigaDuck Manager - Windows MSIX Installer
================================================

IMPORTANTE - Come installare questo pacchetto
==============================================

Questo pacchetto MSIX è firmato con un certificato di test auto-generato.
Per installarlo, devi prima installare il certificato come attendibile.


METODO 1: Script automatico (CONSIGLIATO)
==========================================

1. Scarica TUTTO lo ZIP e estrailo
2. Clicca destro su "install_msix_windows.ps1"
3. Seleziona "Esegui con PowerShell"
4. Conferma i privilegi di amministratore quando richiesto

Lo script installerà automaticamente il certificato e l'app.


METODO 2: Installazione manuale
================================

1. Clicca destro sul file .msix
2. Seleziona "Proprietà"
3. Vai alla scheda "Firme digitali"
4. Seleziona il certificato → Dettagli → Visualizza certificato
5. Clicca "Installa certificato"
6. Seleziona "Computer locale" (richiede privilegi di amministratore)
7. "Posiziona tutti i certificati nel seguente archivio"
8. Sfoglia → "Autorità di certificazione radice attendibili"
9. Completa la procedura guidata
10. Ora puoi fare doppio click sul file .msix per installarlo


METODO 3: PowerShell manuale
=============================

Apri PowerShell come Amministratore ed esegui:

# Estrai e installa il certificato
$cert = (Get-AuthenticodeSignature "LigaDuckManager-Windows-vX.X.X.msix").SignerCertificate
$store = New-Object System.Security.Cryptography.X509Certificates.X509Store("Root","LocalMachine")
$store.Open("ReadWrite")
$store.Add($cert)
$store.Close()

# Installa l'app
Add-AppxPackage -Path "LigaDuckManager-Windows-vX.X.X.msix"


NOTA - Developer Mode
=====================

Se non riesci ad installare l'app, potresti dover abilitare
"Developer Mode" o "Sideloading" su Windows:

1. Impostazioni Windows
2. Aggiornamento e sicurezza → Per sviluppatori
3. Seleziona "Modalità sviluppatore" oppure "Sideload apps"


DISINSTALLAZIONE
================

Per disinstallare l'app:
1. Menu Start → Cerca "LigaDuck Manager"
2. Clicca destro → Disinstalla

Oppure usa PowerShell:
Get-AppxPackage *ligaduck* | Remove-AppxPackage


NOTA SULLA SICUREZZA
====================

Questo certificato è auto-generato per scopo di test/distribuzione interna.
Per una distribuzione pubblica professionale, l'app dovrebbe essere firmata
con un certificato code-signing commerciale da un'autorità certificata
(Digicert, Sectigo, ecc.) oppure distribuita tramite Microsoft Store.


SUPPORTO
========

Per problemi o domande:
https://github.com/Digree/ligaduck/issues
