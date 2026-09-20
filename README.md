# MySchoolMyParents Online

Aplicación Flutter para convertir fotos de lecturas escolares en libros bilingües
locales. El adulto puede revisar el OCR y escuchar el texto completo, un párrafo
o una palabra en el idioma de aprendizaje. Descargable desde
`https://myschoolmyparents.online`.

## Ejecutar

```bash
scripts/flutterw pub get
scripts/flutterw run
```

Para instalar el APK de prueba en un Android conectado con depuración USB o
inalámbrica:

```bash
scripts/flutterw build apk --debug
scripts/flutterw install -d <device-id>
```

La identificación del dispositivo se obtiene con `scripts/flutterw devices`.
En un Samsung Galaxy S25 Ultra se debe habilitar `Opciones de desarrollador` y
`Depuración USB` antes de conectarlo.

## Comprobaciones locales

```bash
scripts/flutterw analyze --no-pub
scripts/flutterw test --no-pub
```

El dominio canónico previsto es `https://myschoolmyparents.online`. Su configuración para autenticación y privacidad está documentada en [docs/configuration/domain.md](docs/configuration/domain.md).

El logo de MySchoolMyParents Online está en
[`assets/branding/my_school_my_parents_logo.png`](assets/branding/my_school_my_parents_logo.png)
y se muestra en la biblioteca. El recurso se generó con fondo transparente para
que también pueda convertirse después en iconos nativos de Android e iOS.
