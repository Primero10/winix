::winix::asigna_valor nombre_base_cargador [file rootname [lindex [file split $argv0] end ] ] cargador constante
::winix::asigna_valor proyecto [ string toupper [file rootname [lindex [file split $argv0] end ] ] ] cargador constante

# Verifica el directorio Base
if [info exists starkit::topdir] {
  ::winix::asigna_valor directorio $::conf(directorio)
} else {
  if { [file type $argv0] == "link" } {
	  ::winix::asigna_valor directorio [file dirname [file readlink $argv0]] cargador link
  } else {
	  ::winix::asigna_valor directorio [file dirname $argv0] cargador directo
  }
}

# Agregamos los paquetes locales
lappend auto_path . [file join [::winix::obtiene_valor directorio] themes] [file join [ ::winix::obtiene_valor directorio] fsdialog ]

# Cargamos paquetes
package require md5
package require csv

set ::winix::administradores ""

set errores_graves 0

if { "[::winix::obtiene_valor modo_web falso]" == "Cierto"} {
	foreach {paquete tipo definicion}  {
		Thread	texto		"Soporte de threads (hilos)"
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
	}
} else {
	foreach {paquete tipo definicion}  {
		Tk 		grafico		"Soporte de X11"
		mysqltcl	texto		"Interfase con MySQL"
		sqlite3	texto		"Interfase con SQLite"
		Iwidgets	grafico		"Libreria de objetos graficos OOP"
		Img		grafico		"Libreria de extensiones para archivos graficos"
		tkpng	graficoopcional		"Libreria de extensiones para archivos graficos"
		BWidget	grafico		"Libreria de Objetos graficos hechos en tcl/tk (Tree)"
		Itcl	texto		"Soporte de OOP"
		snit	texto		"Soporte de OOP"
		Tktable	grafico		"Libreria para cuadriculas"
		Tablelist	grafico		"Extension de lista con encabezados"
		base64	texto		"Extension para almacenar datos binarios en modo texto"
		md5		texto		"Extension para generar firmas de modificaciones"
		csv		texto		"Extension para almacenar informacion para hojas electronicas"
		tile	graficoopcional	"Extension para temas"
		uri		texto		"Soporte para interpretar URL"
		pdf4tcl		textoopcional		"Soporte para interpretar URL"
		Thread	textoopcional		"Soporte de threads (hilos)"
		websocket	texto	"Libreria de soporte de websockets"
		yajltcl	textoopcional	"Soporte de objetos JSON"
		json	textoopcional		"Soporte de objetos JSON"
	} {
		puts -nonewline "$paquete $tipo - "
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
					puts -nonewline "Error al cargar un paquete pero no le hacemos caso"
				}
			}
			grafico {
				if [ catch {
					package require $paquete
				} resultado ] {
					set errores_graves 1
					puts "Error al cargar un paquete $::errorInfo"
				}
			}
			graficoopcional {
				if [ catch {
					package require $paquete
				} resultado ] {
					puts -nonewline "Error al cargar un paquete pero no le hacemos caso"
				}
			}
			default {
				puts -nonewline " ignorado de "
			}
		}
		puts " hecho"
		update
	}
}

if $errores_graves {
	exit
}

eval [package unknown] Tcl [package provide Tcl]

# Verifica el directorio Base y define el archivo de configuracion en consecuencia
if [info exists starkit::topdir] {
	::winix::asigna_valor archivo_configuracion [file join [file dirname $starkit::topdir] [file rootname [lindex [file split $starkit::topdir] end ] ].sqlite] cargador starkit
	::winix::asigna_valor archivo_configuracion_legacy [file join [file dirname $starkit::topdir] [file rootname [lindex [file split $starkit::topdir] end ] ].conf ] cargador starkit
	::winix::asigna_valor bitacora_en_disco [file rootname [lindex [file split $argv0] end ] ].log cargador starkit
} else {
	::winix::asigna_valor archivo_configuracion [file rootname [lindex [file split $argv0] end ] ].sqlite cargador script
	::winix::asigna_valor archivo_configuracion_legacy [file rootname [lindex [file split $argv0] end ] ].conf cargador script
	::winix::asigna_valor bitacora_en_disco [file rootname [lindex [file split $argv0] end ] ].log cargador script
}

::winix::asigna_valor rutinas_cargador 	"[::winix::obtiene_valor directorio]/winix_lib.tcl"	cargador constante
::winix::asigna_valor rutinas_gui 	"[::winix::obtiene_valor directorio]/winix_gui.tcl"	cargador constante
::winix::asigna_valor rutinas_web 	"[::winix::obtiene_valor directorio]/winix_web.tcl"	cargador constante
::winix::asigna_valor rutinas_httpd 	"[::winix::obtiene_valor directorio]/winix_httpd.tcl"	cargador constante
::winix::asigna_valor rutinas_hilos 	"[::winix::obtiene_valor directorio]/winix_hilos.tcl"	cargador constante
#::winix::asigna_valor rutinas_websocket "[::winix::obtiene_valor directorio]/websocket.tcl"	cargador constante
::winix::asigna_valor rutinas_consola	"[::winix::obtiene_valor directorio]/winix_soporte_hilos.tcl"	cargador constante

# Por omision cancela el desplazamiento automatico del debug
set debug(desplaza) 0

# Rutinas Basicas de carga
if [ ::winix::existe_archivo_configuracion rutinas_cargador] {
	source "[::winix::obtiene_valor rutinas_cargador]"
} else {
	puts "No se encontro complemento de cargador"
	puts "Descripcion:[::winix::obtiene_valor rutinas_cargador]" 0 tronar
}

if [ ::winix::existe_archivo_configuracion archivo_configuracion_legacy ] {
	source [::winix::obtiene_valor archivo_configuracion_legacy]
	foreach { var valor } [array get ::conf] {
		::winix::asigna_valor $var $valor cargador legacy
	}
}

if [ ::winix::existe_archivo_configuracion archivo_configuracion ] {
	carga_configuracion_sqlite
}

if { "[::winix::obtiene_valor modo_web falso]" == "Cierto"} {
	if { [ ::winix::existe_archivo_configuracion rutinas_httpd] && [ ::winix::existe_archivo_configuracion rutinas_web] } {
		if [ catch { source "[::winix::obtiene_valor rutinas_httpd ]" } resultado ] { puts "No cargo rutinas_http $::errorInfo"}
		if [ catch { source "[::winix::obtiene_valor rutinas_hilos ]" } resultado ] { puts "No cargo rutinas_hilos $::errorInfo"}
		if [ catch { source "[::winix::obtiene_valor rutinas_consola ]" } resultado ] { puts "No cargo rutinas_hilos $::errorInfo"}

		::winix::inicia_hilos

		puts "Iniciando servidor web en el puerto [::winix::obtiene_valor web_puerto 443]"
		if { "[::winix::obtiene_valor servidor_web_ssl Cierto]" == "Cierto" } {
			if [::winix::inicializa [::winix::obtiene_valor web_puerto 443] [::winix::obtiene_valor server-public.pem server-public.pem] [::winix::obtiene_valor server-private.pem  server-private.pem] ] {
				puts "Error, no se pudo levantar servidor web"
				exit			
			}
		} else {
			if [::winix::inicializa [::winix::obtiene_valor web_puerto 80] "" "" ] {
				puts "Error, no se pudo levantar servidor web"
				exit			
			}
		}
		vwait forever
	}
} else {
	source winix_consola.tcl
	# Cargamos los comandos de itcl para llamarlos directamente
	namespace import itcl::*

	::winix::asigna_valor plataforma gui cargador constante
	::winix::asigna_valor nivel_consola 0 cargador constante
	if [::winix::existe_variable usuario] {
		if [ catch { package require Tk } resultado ] {
			::winix::consola_mensaje "Se requiere wish para correr en modo grafico" 0 trono
		}
		if [ ::winix::existe_archivo_configuracion rutinas_gui] {
			source "[::winix::obtiene_valor rutinas_gui]"
		} else {
			::winix::consola_mensaje "No se encontro complemento de cargador"
			::winix::consola_mensaje "Descripcion:[::winix::obtiene_valor rutinas_gui]" 0 trono
		}
		if { "[::winix::obtiene_valor usuario]" == ""} {
			entrada
			login
		} else {
			entrada
			ingresar
		}
	} else {
		if [ catch { package require Tk } resultado ] {
			::winix::consola_mensaje "Se requiere wish para correr en modo grafico" 0 trono
		}
		if [ ::winix::existe_archivo_configuracion rutinas_gui] {
			source "[::winix::obtiene_valor rutinas_gui ]"
		} else {
			::winix::consola_mensaje "No se encontro complemento de cargador"
			::winix::consola_mensaje "Descripcion:[::winix::obtiene_valor rutinas_gui ]" 0 trono
		}
		entrada
		login
	}
}	

