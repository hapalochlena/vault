
# Merge several commits into one commit:
git reset --soft main
git commit -m "blabla"
git push -f # = force push => overrides history & Stand remote #! => NUR NUTZEN WENN MAN GANZ WEISS WAS MAN MACHT UND KEIN ANDERER AUF DIESEM BRANCH GEARBEITET HAT !!!

# Stash changes before jumping to other branch
git stash # speichert meine Änderungen und wird zurückversetzt zu letztem commit
# dann Änderungen wieder einfügen:
git stash apply # fügt gespeicherte Änderungen wieder ein, behält aber den gespeicherten Stash bei => besser, weil manchmal gepoppt und dann doch nicht funktioniert und dann gabs merge conflict
git stash pop # gespeicherte Änderungen wieder angewendet und von Stash gelöscht
git stash clear # ganzen Stash löschen

# delete local branch
git branch -d old-branch

# rename branch
git branch -m old-name new-name

# Git config
git config --list 
git config --global user.email your_email@abc.example
git config --global user.name
# confirm
git config user.email

