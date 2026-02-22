//-------------------------------------
// Document options
//
#let option = (
  type : "final",
  //type : "draft",
  lang : "en",
  //lang : "de",
  //lang : "fr",
)
//-------------------------------------
// Optional generate titlepage image
//
#import "@preview/fractusist:0.1.1":*  // only for the generated images

#let titlepage_logo= dragon-curve(
  12,
  step-size: 10,
  stroke-style: stroke(
    //paint: gradient.linear(..color.map.rocket, angle: 135deg),
    paint: gradient.radial(..color.map.rocket),
    thickness: 3pt, join: "round"),
  height: 10cm,
)

//-------------------------------------
// Metadata of the document
//
#let doc= (
  title    : [*Sistemas de identificación*],
  abbr     : "IS-444",
  subtitle : [_Automatizacion Criptografica y Sistemas de Identificacion Digital_],
  url      : "https://synd.hevs.io",
  logos: (
    tp_topleft  : image("resources/img/synd.svg", height: 1.2cm),
    tp_topright : image("resources/img/logo.jpg", height: 2cm),
    tp_main     : titlepage_logo,
    header      : image("resources/img/logo.jpg", width: 1.5cm),
  ),
  authors: (
    (
      name        : "Isaias Ramos Lopez",
      abbr        : "irl",
      email       : "isaias.ramos.27@unsch.edu.pe",
      url         : "https://synd.hevs.io",
    ),
    (
      name        : "Josue r. Tinco Palomino",
      abbr        : "jrtp",
      email       : "josue.tinco.27@unsch.edu.pe",
      url         : "https://synd.hevs.io",
    ),
  ),
  school: (
    name        : "Universidad Nacional de San Cristobal de Huamanga",
    major       : "Facultad de Ingenieria de Minas Geologia y Civil",
    orientation : "Escuela Profesional de Ingenieria de Sistemas",
    url         : "https://synd.hevs.io",
  ),
  course: (
    name     : "Seguridad Informática",
    url      : "https://course.hevs.io/did/eda-docs/",
    prof     : "Ing. Celia E. Martinez Cordova",
    class    : [IS 444],
    semester : "2026",
  ),
  keywords : ("Typst", "Template", "Report", "HEI-Vs", "Systems Engineering", "Infotronics"),
  version  : "v0.1.0",
)

#let date= datetime.today()

//-------------------------------------
// Settings
//
#let tableof = (
  toc: true,
  tof: false,
  tot: false,
  tol: false,
  toe: false,
  maxdepth: 3,
)

#let gloss    = true
#let appendix = false
#let bib = (
  display : true,
  path  : "bibliography.bib",
  style : "ieee", //"apa", "chicago-author-date", "chicago-notes", "mla"
)
