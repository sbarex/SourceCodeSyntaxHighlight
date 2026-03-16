# TODO

- [ ] When compiling `highlight` avoid the creation of the static library `.a` before the CLI otherwise it will be linked in the executable instead of the dynamic one taking up space. 
- [x] Sometime when compiling the app the custom lua plugins are not embedded.
- [ ] Update the application help.
- [ ] Consider whether to incorporate both light and dark styles in the html in order to automatically adapt to the system's style. For RTF [see this link](https://eclecticlight.co/2018/12/10/rendering-rich-text-in-dark-mode/). 


# SPUNTI

Nuovo qlsyntax

- Usare app firmata e sandbox. Questo comporta la riscrittura delle preferenze
- Creare un groupcontainer condiviso tra app ed estensione in cui copiare le risorse di highlight
- Evitare l’uso di colorize.sh e usare tutto da codice nativo a meno che non venga richiesto un pre processore 
- Gestire internamente alcuni preprocessori (come le plist binarie)
- Valutare di gestire git da codice nativo senza tool esterni. Eventualmente rimuovere supporto di hg
- Usare più appex con codice condiviso specializzati per determinate estensioni (ad esempio app, eseguibili o per i file senza estensioni) rendendo l’uso più modulare

- usare una funzione che riceva uti ed estensione e restituisca la sintassi da usare per l'evidenziazione.
- Consentire di scegliere se l'output della quick look sia html o rtf (ottenuto dalla conversione dall'html) spiegando che rtf torna utile in certe modalità di anteprima (gallery? file info?) E valutare se il passaggio da html -> rtf sia molto peggiorativo della generazione diretta di codcie rtf 

Avere una vista dei file per estensione, per ogni estensione gli uti associati:
```swift
import UniformTypeIdentifiers

let fileExtension = "jpg"

let types = UTType.types(tag: fileExtension,
                         tagClass: .filenameExtension,
                         conformingTo: nil)

for type in types {
    print(type.identifier)
}

```
