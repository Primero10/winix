#rename proc _proc
#_proc proc {name arglist body} {
#    uplevel 1 [list _proc $name $arglist $body]
#    uplevel 1 [list trace add execution $name enter [list ::proc_start $name]]
#}
#_proc proc_start {name command op} {
#    puts "$name -> [info frame [info level]]"
#}
set errores_graves 0

foreach {paquete tipo definicion}  {
	Itcl		texto	"Soporte de Clases"
	html		texto	"Soporte de html"
	mysqltcl	texto	"Soporte de MySQL"
} {
	switch $tipo {
		texto {
			if [ catch {
				package require $paquete
			} resultado ] {
				set errores_graves 1
				puts "Error al cargar un paquete $::errorInfo"
			}
		}
		textoopcional {
			if [ catch {
				package require $paquete
			} resultado ] {
			}
		}
		grafico {
			if { "[::winix::obtiene_valor modalidad texto]" == "grafico" } {
				if [ catch {
					package require $paquete
				} resultado ] {
					set errores_graves 1
				puts "Error al cargar un paquete $::errorInfo"
				}
			}
		}
		graficoopcional {
			if { "[::winix::obtiene_valor modalidad texto]" == "grafico" } {
				if [ catch {
					package require $paquete
				} resultado ] {
				}
			}
		}
	}
	if { "[::winix::obtiene_valor modalidad texto]" == "grafico" } {
		update
	}
}

namespace import itcl::*

if $errores_graves {
	exit
}

eval [package unknown] Tcl [package provide Tcl]

# Por omision cancela el desplazamiento automatico del debug
set debug(desplaza) 0

# Rutinas Basicas de carga
source "winix_lib.tcl"

if [ ::winix::existe_archivo_configuracion archivo_configuracion_legacy ] {
	source [::winix::obtiene_valor archivo_configuracion_legacy]
	foreach { var valor } [array get ::conf] {
		::winix::asigna_valor $var $valor cargador legacy
	}
} else {
	puts "No hay archivo de configuracion [::winix::obtiene_valor archivo_configuracion_legacy]"
}

if [ ::winix::existe_archivo_configuracion archivo_configuracion ] {
	carga_configuracion_sqlite
}

source winix_web.tcl
source winix_lib.tcl
source winix_http_sockets.tcl
source winix_consulta.tcl

::winix::inicializar

::winix::carga_mimes
