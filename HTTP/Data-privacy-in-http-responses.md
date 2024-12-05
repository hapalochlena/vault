# Hiding personal data of the user in the Network tab

NETWORK TAB WENN MAN BZA ID SCHICKT
=> RESPONSE SIEHT MAN DIE SENSIBLEN PERSÖNLICHEN DATEN AUS DER DATENBANK, 
die zurückgeschickt werden, wenn die checkBzaId Funktion in der Datenbank prüft, ob die BzA ID bereits vorhanden ist
(steht dann sowas wie Postleizahl, Adresse etc. die zu dieser BzA ID gehören)

=> nach Implementierung von Backend Funktionen:

NACH UMSETZUNG: IM NETWORK TAB "RESPONSE" KEINE PERSÖNLICHEN DATEN MEHR SONDERN NUR NOCH RESPONSE CODE 400, oder wenn positiv: 
wäre in Response auch ähnliches Ergebnis, aber gewisse Daten wären nicht sichtbar, sondern nur die BzA Daten (Zuschussreferenz Daten nicht sichtbar)

**AZURE FUNCTION FILTERT QUASI GEWISSE RESPONSE DATEN RAUS**

VERGLEICH mit UploadToken Funktion:
mal in ganzen code der funktion gucken: hier steht soooooooo viel funktionalität drin, die alles in der azure function steckt,
die aber "verdeckt" ist => IM FRONTEND ERSCHEINT LEDIGLICH AM ENDE DAS UPLOADTOKEN (und noch die eine andere sache)
alles was ZURÜCK KOMMT IST UPLOADSTRING UND TOKEN


## Beispiel wie man FUNKTION RESPONSE TYPEN muss:

Q:
Hey guys, quick question. I have an API response with only three properties I need and 50 which I don't need. Would it be safe to go this way to type the response?

export interface ZuschussreferenzApiResponse {
  zuschussentscheidung: {
    zuschussentscheidungsdatum: string;
    bzaId: string;
    vorhabenInformation: {
      antragstellerArt: string;
      [key: string | number]: any;
    };
    [key: string | number]: any;
  };
}

**=> also: wir definieren eine COMPONENT namens ApiResponse, wo wir festlegen, welche Properties in der Response geschickt werden sollen**

A:
Would not `Partial<ZuschussreferenzApiResponse>` fix your problem? Of course depends on your use case.