# Dibuja la entrada GUI al sistema
#
# Personalizar para cada sistema
#
# -------------------------------------------------------------------------------------------------------------

proc entrada { } {
	debug "Solicitando Login..."

	catch { 
		image create photo logo_login -file [::winix::obtiene_valor directorio .]/imagenes/[::winix::obtiene_valor logo_login logo_login.jpg]
	}

	toplevel .login -background white
	catch {
		label .login.logo -background white -image logo_login -border 6 -relief sunken -fg [::winix::obtiene_valor color_programa_fondo #6699cc]
	}
	label .login.sistema -text "[::winix::obtiene_valor empresa {Desarrollos Informáticos de México, S.C.}]" \
		-background  [::winix::obtiene_valor color_programa_fondo #6699cc] -fg [::winix::obtiene_valor color_programa_texto white] -border 5 -relief ridge -font {Arial 16 bold}
	label .login.empresa -text "[::winix::obtiene_valor sistema {Proyecto Pegaso}]" \
		-background  [::winix::obtiene_valor color_programa_fondo #6699cc] -fg [::winix::obtiene_valor color_programa_texto white] -font {Arial 12 bold}
	if [::winix::existe_variable usuario] {
	} else {
		frame .login.usuario  -background  [::winix::obtiene_valor color_programa_fondo #6699cc] -border 5 -relief flat
		label .login.usuario.texto \
			-text Usuario:  -background  [::winix::obtiene_valor color_programa_fondo #6699cc] -width 10 -anchor e -font {Arial 16 bold} -fg [::winix::obtiene_valor color_programa_texto white]
		entry .login.usuario.entry -textvar ::conf(usuario) -font {Arial 16 bold} -fg [::winix::obtiene_valor color_programa_fondo #6699cc] -bg [::winix::obtiene_valor color_programa_texto black]
		frame .login.clave -background  [::winix::obtiene_valor color_programa_fondo #6699cc] -border 5 -relief flat
		label .login.clave.texto \
			-text Clave: -background  [::winix::obtiene_valor color_programa_fondo #6699cc] -width 10 -anchor e -font {Arial 16 bold} -fg [::winix::obtiene_valor color_programa_texto white]
		entry .login.clave.entry -show * -textvar ::conf(clave) -font {Arial 16 bold}  -fg [::winix::obtiene_valor color_programa_fondo #6699cc] -bg [::winix::obtiene_valor color_programa_texto black]
	}
	label .login.mensaje -background white -width 10 -anchor e
	frame .login.desarrollador -background white -border 2 -relief ridge
	frame .login.desarrollador.datos
	label .login.desarrollador.datos.texto -text "Desarrollos Informáticos de México, S.C." -background white 
	label .login.desarrollador.datos.www -text "www.dim.com.mx" -background white 
	label .login.avance -font {Arial 10 bold} -fg [::winix::obtiene_valor color_programa_texto] -background [::winix::obtiene_valor color_programa_texto white] -anchor w

	pack .login.sistema .login.empresa -fill x 
	catch {
	  pack .login.logo -fill x 
	}
	if [winfo exist .login.usuario] {
		pack .login.usuario .login.clave -expand true -fill x
		pack .login.usuario.entry .login.usuario.texto -side right
		pack .login.clave.entry .login.clave.texto -side right
	} 

	pack .login.mensaje -fill x
	pack .login.desarrollador -fill x
	pack .login.avance -fill x

	pack .login.desarrollador.datos -side left -fill x -expand yes
	catch {
		pack .login.desarrollador.logo -side right
	}

	pack .login.desarrollador.datos.texto -side top -fill x
	pack .login.desarrollador.datos.www -side top -fill x

	centrar_pantalla .login
}
