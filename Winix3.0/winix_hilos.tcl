package provide winix 3.0


namespace eval winix {
	proc ::winix::inicia_hilos {} {
		::tsv::set hilos master [ ::thread::id ]
		::tsv::set entorno directorio [::winix::obtiene_valor directorio]
		::tsv::set entorno debug [::winix::obtiene_valor debug false]
		::tsv::set entorno nivel [::winix::obtiene_valor nivel 6]

		::thread::errorproc error_hilo
	
		::winix::inicia_consola

		puts "Creando pool para manejar sockets"

		::tsv::set hilos pool_socks \
		[ ::tpool::create \
			-minworkers [::winix::obtiene_valor thread_sock_minimos 2 ] \
			-maxworkers [::winix::obtiene_valor thread_sock_maximos 100 ] \
			-idletime 60 \
			-initcmd [ subst {
				source winix_clase.tcl
				source winix_soporte_hilos.tcl

				::winix::asigna_valor modo_web Cierto				 						cargador "Inicia thread"
				::winix::asigna_valor directorio [::winix::obtiene_valor directorio ] 						cargador "Inicia thread"
				::winix::asigna_valor archivo_configuracion [::winix::obtiene_valor archivo_configuracion ] 			cargador "Inicia thread"
				::winix::asigna_valor archivo_configuracion_legacy [::winix::obtiene_valor archivo_configuracion_legacy ] 	cargador starkit
				::winix::asigna_valor plataforma sockets									cargador starkit

				source winix_carga_socks.tcl

				::winix::consola_mensaje "Thread creado para atencion a conexiones" 6

			} ] \
			-exitcmd ::winix::finalizar
		]
		
		puts "Creando pool para manejar instancias"

		::tsv::set hilos pool_web \
		[ ::tpool::create \
			-minworkers [::winix::obtiene_valor thread_instancias_minimos 2 ] \
			-maxworkers [::winix::obtiene_valor thread_instancias_maximos 100 ] \
			-idletime 60 \
			-initcmd [ subst {
				source winix_clase.tcl
				source winix_carga_thread.tcl
			} ] \
			-exitcmd ::winix::finalizar
		]

		::thread::send [ ::tsv::get hilos consola ] ::winix::consola_conexiones
		
	}
	
	proc ::winix::inicia_consola { } {
		::tsv::set hilos consola    [ ::thread::create ]

		::thread::send [ ::tsv::get hilos consola ] [subst {
			source winix_clase.tcl
			source winix_consola.tcl

			::winix::asigna_valor nivel_consola 	[::winix::obtiene_valor nivel_consola 5 ] 	cargador "Inicia thread"
			::winix::asigna_valor consola_web 	[::winix::obtiene_valor consola_web false ] 	cargador "Inicia thread"

			::winix::inicializa_entorno
			::winix::consola_mensaje "Consola de servidor iniciada." 6
		} ]
	}

	proc ::winix:pool_sockets { sock ip port } {
		::tpool::post [ ::tsv::get hilos pool_socks ] [ list ::winix::accept $sock $ip $port ]
	}
}