
Checkov.yml: 
gibt es 2x, in einem wird checkov gedownloadet und die Config Datei auf einem lokalen Pfad hinterlegt 
(sieht man in DevOps ausgeführter Pipeline im Checkov step: `cat [dateipfad]`), 
der dann nachher wieder aufgerufen wird in der Pipeline

=> entscheidende Änderung in validate.yml: 
hier wird Checkov template aufgerufen, 
da müssen wir ändern, dass er die Config woanders hernimmt



