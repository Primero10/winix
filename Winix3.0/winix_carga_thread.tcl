#rename proc _proc
#_proc proc {name arglist body} {
#    uplevel 1 [list _proc $name $arglist $body]
#    uplevel 1 [list trace add execution $name enterstep [list ::proc_start $name]]
#}
#_proc proc_start {name command op} {
#    puts "$name >> $command"
#}

set ::winix::administradores ""

set ::folio 0

set errores_graves 0
foreach {paquete tipo definicion}  {
    mysqltcl	texto		"Interfase con MySQL"
    sqlite3	texto		"Interfase con SQLite"
    Itcl	texto		"Soporte de OOP"
    smtp	texto		"Soporte para correo electronico"
    mime	texto		"Soporte para mime"
    base64	texto		"Extension para almacenar datos binarios en modo texto"
    md5		texto		"Extension para generar firmas de modificaciones"
    csv		texto		"Extension para almacenar informacion para hojas electronicas"
    uri		texto		"Soporte para interpretar URL"
    Thread	texto		"Soporte de threads (hilos)"
    yajltcl	texto		"Soporte de objetos JSON"
    json	texto		"Soporte de objetos JSON"
} {
	if { "$tipo" == "texto" } {
		if [ catch {
			package require $paquete
		} resultado ] {
			set errores_graves 1
			puts "Problemas al cargar paquete $paquete"
			puts "Descripcion:$definicion"
			puts "$resultado"
			puts ""
		}
	}
}

if $errores_graves {
	::winix::consola_mensaje "" 0 tronar
}

# Cargamos los comandos de itcl para llamarlos directamente
namespace import itcl::*

eval [package unknown] Tcl [package provide Tcl]

source winix_consulta.tcl
source winix_lib.tcl
source winix_web.tcl
source winix_soporte_hilos.tcl
source winix_http_instancias.tcl
source websocket.tcl
