namespace eval winix {
	variable req
	variable objeto_consulta
	variable stack_instancias

	proc ::winix::inicializa {port certfile keyfile } {

		if {$certfile ne "" || "[::winix::obtiene_valor servidor_web_ssl Cierto]" == "Cierto"} {
			::winix::consola_mensaje "Inicializando en puerto $port SSL" 15
			package require tls
			::tls::init \
				-certfile $certfile \
				-keyfile  $keyfile \
				-cipher DEFAULT:!EDH \
				-ssl2 0 \
				-ssl3 0\
				-tls1 1 \
				-require 0 \
				-request 0

			if [ catch { ::winix::asigna_valor Server_Socket [::tls::socket -server ::winix::accept $port ] Servidor Master } resultado ] {
				puts "Problemas al abrir socket $resultado"
				exit
			}
			::winix::consola_mensaje "Se abrio socket de servidor: [::winix::obtiene_valor Server_Socket]" 3

		} else {
			::winix::consola_mensaje "Inicializando en puerto $port Plain Text" 15
			if [ catch { ::winix::asigna_valor Server_Socket [socket -server ::winix::accept $port ] Servidor Master } resultado ] {
				puts "Problemas al abrir socket $resultado"
				exit
			}
			return 0
		}

		::tsv::set entorno Server_Socket [::winix::obtiene_valor Server_Socket]

		return 0
	}

	proc ::winix::accept {sock ip port} {
		after 0 [ list ::winix::pool_sockets $sock $ip $port ]
	}

}
