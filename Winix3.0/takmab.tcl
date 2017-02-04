#!/opt/ActiveTcl-8.6/bin/wish8.6
##############################################################################
# Cargador Winix
#
# Autor: Ricardo Cuevas Camarena
# Proyecto: Winix
# Archivo: winix.tcl
# Version: 3.0
# Descripcion: Programa Principal del Sistema Winix
#              Se encarga de:
#		1.- Conectarse a la base de datos.
#		2.- Verificar configuracion del sistema
#		3.- Verificar lista de programas
#		4.- Verificar privilegios del usuario y que programas tiene acceso
#		5.- Armar menus del sistema
#		6.- Conectarse a bases de datos Primarias, Principales y Alternas
#
# La conexion puede ser en modalidad GUI o WEB, dependiendo de la variable modo_web
# en Cierto o Falso, y son excluyentes
#
# Derechos Reservados 2005,2006 Desarrollos Informáticos de México, S.C.
#
# Este archivo es parte del Entorno de Desarrollo Winix, Como tal no es parte
# especificamente de un Sistema, por lo que puede utilizarse con modificaciones
# en otros desarrollos de Desarrollos Informáticos de México, S.C. sin que implique
# problemas de Licenciamiento por Desarrollos Especificos.
# Desarrollos Informáticos de México, S.C. Podra extender licencias de desarrollo
# con la Premisa de respetar estas advertencias integras.
##############################################################################
#rename proc _proc
#_proc proc {name arglist body} {
#    uplevel 1 [list _proc $name $arglist $body]
#    uplevel 1 [list trace add execution $name enterstep [list ::proc_start $name]]
#}
#_proc proc_start {name command op} {
#    puts "$name >> $command"
#}

source winix_clase.tcl

if {"[lindex $argv 0]" == "web" } {
	::winix::asigna_valor modo_web Cierto Cargador "Linea de comando"
	::winix::asigna_valor servidor_web Maestro Cargador "Servidor Master"
}

source winix_carga_master.tcl