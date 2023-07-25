; El programa empieza de entrada con una matriz de 5x5 con todo el abecedario menos la J leída de un archivo.
; Le pedimos al usuario que ingrese un mensaje que se dividirá en bloques de dos caracteres,
; que no se repita ninguna letra en el mismo bloque ni tenga J.
; Si el mensaje tiene letras impares, agregar una X para formar el bloque. Si X es la última, agregar Z.
; El programa va a buscar en la matriz los dos primeros caracteres y dependiendo su posición, obtendrá
; dos caracteres más y los pondra en un nuevo mensaje.
; Luego le preguntamos al usuario si quiere codificar el mensaje o quiere decodificarlo.

; A B C D E
; F G H I K     Ingreso el mensaje "Puertapo" -> PU-ER-TA-PO
; L M N O P
; Q R S T U     El mensaje codificado -> UZ-BU-QD-LP (U abajo de P, Z abajo de U, B misma fila esquina opuesta de E, etc)
; V W X Y Z     El mensaje decodificado -> PU-ER-TA-PO (P arriba de U, U arriba de Z, E misma fila esquina opuesta de B, etc)

global main
extern printf
extern gets
extern scanf
extern fopen
extern fgets
extern fclose
extern strlen

section	.data
    ingresarMensaje db "Ingrese el mensaje sin J ni caracteres especiales o repetidos en un mismo bloque:", 10, 0
    ingresarOpcion db "Ingrese C para codificar mensaje o D para decodificarlo:", 10, 0

    mensajeCodificadoSalida db "El mensaje codificado es: %s", 10, 0
    mensajeDecodificadoSalida db "El mensaje decodificado es: %s", 10, 0

    fileName db "Matriz.txt", 0
    mode db "r", 0
    fileHandle dq 1
    mensajeErrorArchivo db "Error en el archivo Matriz.dat", 10, 0

    matrix  db  "A", "B", "C", "D", "E"
		    db  "F", "G", "H", "I", "K"
			db  "L", "M", "N", "O", "P"
            db  "Q", "R", "S", "T", "U"
            db  "V", "W", "X", "Y", "Z"

    posicion db 0
    fila1 db 1
    columna1 db 1
    fila2 db 1
    columna2 db 1

    posicionLetra1 db 0
    posicionLetra2 db 0

section .bss
    matriz resb 25
    matrizBuffer resb 100
    mensajeConEspacios resb 100
    mensaje resb 100
    nuevoMensaje resb 100
    opcion resb 1

section .text
main:
    sub rsp, 8

; ////////////////////////////////////////////////////////////////////////////////////////////////////////
; ////////////////////////////////////////////////////////////////////////////////////////////////////////
; //////////////////////////////////////////// Archivo Matriz ////////////////////////////////////////////
; ////////////////////////////////////////////////////////////////////////////////////////////////////////
; ////////////////////////////////////////////////////////////////////////////////////////////////////////

    ; Abrir archivo
    mov rdi, fileName
    mov rsi, mode
    call fopen

    cmp rax, 0
    jle closeFile
    mov qword [fileHandle], rax

    ; Leer archivo
    mov rdi, matriz
    mov rsi, 26
    mov rdx, [fileHandle]
    call fgets

    ; Verificar si hay exactamente 25 caracteres
    mov rdi, matriz
    call strlen
    cmp rax, 25
    jne closeFile

    ; Cerrar archivo
    mov rdi, [fileHandle]
    call fclose

; //////////////////////////////////////////////////////////////////////////////////////////////////////
; //////////////////////////////////////////////////////////////////////////////////////////////////////
; //////////////////////////////////////////// Validaciones ////////////////////////////////////////////
; //////////////////////////////////////////////////////////////////////////////////////////////////////
; //////////////////////////////////////////////////////////////////////////////////////////////////////

; Ingreso de mensaje a codificar o decodificar
entradaMensaje:
    mov rdi, ingresarMensaje
    call printf

    mov rdi, mensajeConEspacios
    call gets

; Verificar que mensaje no esté vacío
    cmp byte [mensajeConEspacios], 0
    je entradaMensaje

; Eliminar espacios en el mensaje
    mov rdi, mensajeConEspacios
    mov rsi, mensaje

eliminarEspacios:
    mov al, byte [rdi]
    inc rdi

    cmp al, 0
    je finEliminarEspacios

    cmp al, " "
    je saltarEspacio

    mov byte [rsi], al
    inc rsi

saltarEspacio:  
    jmp eliminarEspacios

finEliminarEspacios:
    mov byte [rsi], 0 

; Convertir mensaje a mayúsculas
    mov rdi, mensaje

mensajeMayusculas:
    mov al, byte [rdi]
    inc rdi

    cmp al, 0
    je finMayusculas

    cmp al, "a"
    jb mensajeMayusculas

    cmp al, "z"
    ja mensajeMayusculas

    sub al, 32

    mov [rdi - 1], al
    jmp mensajeMayusculas

finMayusculas:

; Verificar que el mensaje no tenga la J y este entre A y Z
    mov rdi, mensaje
    xor rcx, rcx

contieneJ:
    mov al, byte [rdi]
    inc rdi

    cmp al, 0
    je finContieneJ

    cmp al, "J"
    je entradaMensaje

    cmp al, "A"
    jb entradaMensaje

    cmp al, "Z"
    ja entradaMensaje

    inc rcx
    jmp contieneJ

finContieneJ:

; Agregar una X al final si el mensaje es impar o una Z si ya hay X
    test rcx, 1
    jz mensajeEsPar

    cmp byte [mensaje + rcx - 1], "X"
    je hayXAlFinal

    mov byte [mensaje + rcx], "X"
    mov byte [mensaje + rcx + 1], 0

    jmp mensajeEsPar

hayXAlFinal:
    mov byte [mensaje + rcx], "Z"
    mov byte [mensaje + rcx + 1], 0

mensajeEsPar:

; Verificar que el mensaje tenga una sola instancia de letra por cada bloque
    mov rdi, mensaje

letraRepetida:
    mov al, byte [rdi]
    mov dl, byte [rdi + 1]
    add rdi, 2

    cmp al, 0
    je finLetraRepetida

    cmp al, dl
    je entradaMensaje

    jmp letraRepetida

finLetraRepetida:

; Ingreso de opción de cifrado
entradaOpcion:
    mov rdi, ingresarOpcion
    call printf

    mov rdi, opcion
    call gets

    cmp byte [opcion + 1], 0
    jne entradaOpcion

    cmp byte [opcion], "c"
    je opcionMayuscula

    cmp byte [opcion], "d"
    je opcionMayuscula

    jmp verificarOpcion

opcionMayuscula:
    sub byte [opcion], 32

verificarOpcion:
    cmp byte [opcion], "C"
    je codificar

    cmp byte [opcion], "D"
    je decodificar

    jmp entradaOpcion

; /////////////////////////////////////////////////////////////////////////////////////////////////////////////
; /////////////////////////////////////////////////////////////////////////////////////////////////////////////
; //////////////////////////////////////////// Fin de Validaciones ////////////////////////////////////////////
; /////////////////////////////////////////////////////////////////////////////////////////////////////////////
; /////////////////////////////////////////////////////////////////////////////////////////////////////////////

; Comienzo del proceso de cifrar el mensaje
codificar:
    mov rdi, mensaje
    mov rsi, nuevoMensaje

    add rsp, 8
    call codificarMensaje
    sub rsp, 8

    mov byte [rsi], 0
    mov rdi, mensajeCodificadoSalida
    mov rsi, nuevoMensaje
    call printf

    jmp fin

; Comienzo del proceso de decodificar un mensaje cifrado
decodificar:
    mov rdi, mensaje
    mov rsi, nuevoMensaje

    add rsp, 8
    call decodificarMensaje
    sub rsp, 8

    mov byte [rsi], 0
    mov rdi, mensajeDecodificadoSalida
    mov rsi, nuevoMensaje
    call printf

    jmp fin

closeFile:
    mov rdi, mensajeErrorArchivo
    call printf

    mov rdi, [fileHandle]
    call fclose

; Fin del programa
fin:
    add rsp, 8
    ret

; ///////////////////////////////////////////////////////////////////////////////////////////////////
; ///////////////////////////////////////////////////////////////////////////////////////////////////
; //////////////////////////////////////////// Codificar ////////////////////////////////////////////
; ///////////////////////////////////////////////////////////////////////////////////////////////////
; ///////////////////////////////////////////////////////////////////////////////////////////////////

codificarMensaje:
    mov rbx, 25
    mov byte [posicion], 0
    movzx ecx, byte [posicion]

    mov byte [fila1], 1
    mov byte [columna1], 1
    mov byte [fila2], 1
    mov byte [columna2], 1

    mov byte [posicionLetra1], 0
    mov byte [posicionLetra2], 0

    mov al, byte [rdi]
    inc rdi

    cmp al, 0
    je finCodificarMensaje

siguienteLetraCodificar:
    cmp al, byte [matriz + ecx]
    je buscarSegundaLetraCodificar

    inc byte [posicion]
    movzx ecx, byte [posicion]
    inc byte [posicionLetra1]

    inc byte [columna1]
    cmp byte [columna1], 6
    jne sigueCodificar

    mov byte [columna1], 1
    inc byte [fila1]

sigueCodificar:
    dec rbx
    cmp rbx, 0
    jg siguienteLetraCodificar
        
    jmp codificarMensaje

buscarSegundaLetraCodificar:
    mov rbx, 25
    mov byte [posicion], 0
    movzx ecx, byte [posicion]

    mov al, byte [rdi]
    inc rdi

    cmp al, 0
    je finCodificarMensaje

siguienteLetraCodificar2:
    cmp al, byte [matriz + ecx]
    je reemplazarLetrasCodificar

    inc byte [posicion]
    movzx ecx, byte [posicion]
    inc byte [posicionLetra2]

    inc byte [columna2]
    cmp byte [columna2], 6
    jne sigueCodificar2

    mov byte [columna2], 1
    inc byte [fila2]

sigueCodificar2:
    dec rbx
    cmp rbx, 0
    jg siguienteLetraCodificar2

    jmp buscarSegundaLetraCodificar

reemplazarLetrasCodificar:
    movzx ecx, byte [fila1]
    movzx edx, byte [fila2]
    cmp ecx, edx
    je filasIgualesCodificar

    movzx ecx, byte [columna1]
    movzx edx, byte [columna2]
    cmp ecx, edx
    je columnasIgualesCodificar

    call tomarVertices

    jmp codificarMensaje

; Si los caracteres se encuentran en la misma fila, de cada caracter el situado a la derecha.
filasIgualesCodificar:
    cmp byte [columna1], 5
    je finDeFilaCodificar1

    jmp sigueFilaCodificar1

finDeFilaCodificar1:
    movzx ecx, byte [posicionLetra1]
    mov dl, byte [matriz + ecx - 4]
    mov byte [rsi], dl
    inc rsi

    jmp compararSiguienteFilaCodificar

sigueFilaCodificar1:
    movzx ecx, byte [posicionLetra1]
    mov dl, byte [matriz + ecx + 1]
    mov byte [rsi], dl
    inc rsi

compararSiguienteFilaCodificar:
    cmp byte [columna2], 5
    je finDeFilaCodificar2

    jmp sigueFilaCodificar2

finDeFilaCodificar2:
    movzx ecx, byte [posicionLetra2]
    mov dl, byte [matriz + ecx - 4]
    mov byte [rsi], dl
    inc rsi

    jmp codificarMensaje

sigueFilaCodificar2:
    movzx ecx, byte [posicionLetra2]
    mov dl, byte [matriz + ecx + 1]
    mov byte [rsi], dl
    inc rsi

    jmp codificarMensaje

; Si los caracteres se encuentran en la misma columna, tomar el caracter situado debajo.
columnasIgualesCodificar:
    cmp byte [fila1], 5
    je finDeColumna1Codificar

    jmp sigueColumnaCodificar1

finDeColumna1Codificar:
    movzx ecx, byte [posicionLetra1]
    mov dl, byte [matriz + ecx - 20]
    mov byte [rsi], dl
    inc rsi

    jmp compararSiguienteColumnaCodificar

sigueColumnaCodificar1:
    movzx ecx, byte [posicionLetra1]
    mov dl, byte [matriz + ecx + 5]
    mov byte [rsi], dl
    inc rsi

compararSiguienteColumnaCodificar:
    cmp byte [fila2], 5
    je finDeColumna2Codificar

    jmp sigueColumnaCodificar2

finDeColumna2Codificar:
    movzx ecx, byte [posicionLetra2]
    mov dl, byte [matriz + ecx - 20]
    mov byte [rsi], dl
    inc rsi

    jmp codificarMensaje

sigueColumnaCodificar2:
    movzx ecx, byte [posicionLetra2]
    mov dl, byte [matriz + ecx + 5]
    mov byte [rsi], dl
    inc rsi

    jmp codificarMensaje

finCodificarMensaje:
    ret

; /////////////////////////////////////////////////////////////////////////////////////////////////////
; /////////////////////////////////////////////////////////////////////////////////////////////////////
; //////////////////////////////////////////// Decodificar ////////////////////////////////////////////
; /////////////////////////////////////////////////////////////////////////////////////////////////////
; /////////////////////////////////////////////////////////////////////////////////////////////////////

decodificarMensaje:
    mov rbx, 25
    mov byte [posicion], 0
    movzx ecx, byte [posicion]

    mov byte [fila1], 1
    mov byte [columna1], 1
    mov byte [fila2], 1
    mov byte [columna2], 1

    mov byte [posicionLetra1], 0
    mov byte [posicionLetra2], 0

    mov al, byte [rdi]
    inc rdi

    cmp al, 0
    je finDecodificarMensaje

siguienteLetraDecodificar:
    cmp al, byte [matriz + ecx]
    je buscarSegundaLetraDecodificar

    inc byte [posicion]
    movzx ecx, byte [posicion]
    inc byte [posicionLetra1]

    inc byte [columna1]
    cmp byte [columna1], 6
    jne sigueDecodificar

    mov byte [columna1], 1
    inc byte [fila1]

sigueDecodificar:
    dec rbx
    cmp rbx, 0
    jg siguienteLetraDecodificar
        
    jmp decodificarMensaje

buscarSegundaLetraDecodificar:
    mov rbx, 25
    mov byte [posicion], 0
    movzx ecx, byte [posicion]

    mov al, byte [rdi]
    inc rdi

    cmp al, 0
    je finDecodificarMensaje

siguienteLetraDecodificar2:
    cmp al, byte [matriz + ecx]
    je reemplazarLetrasDecodificar

    inc byte [posicion]
    movzx ecx, byte [posicion]
    inc byte [posicionLetra2]

    inc byte [columna2]
    cmp byte [columna2], 6
    jne sigueDecodificar2

    mov byte [columna2], 1
    inc byte [fila2]

sigueDecodificar2:
    dec rbx
    cmp rbx, 0
    jg siguienteLetraDecodificar2
        
    jmp buscarSegundaLetraDecodificar

reemplazarLetrasDecodificar:
    movzx ecx, byte [fila1]
    movzx edx, byte [fila2]
    cmp ecx, edx
    je filasIgualesDecodificar

    movzx ecx, byte [columna1]
    movzx edx, byte [columna2]
    cmp ecx, edx
    je columnasIgualesDecofidicar

    call tomarVertices

    jmp decodificarMensaje

; Si los caracteres se encuentran en la misma fila, de cada caracter el situado a la izquierda.
filasIgualesDecodificar:
    cmp byte [columna1], 1
    je finDeFilaDecodificar1

    jmp sigueFilaDecodificar1

finDeFilaDecodificar1:
    movzx ecx, byte [posicionLetra1]
    mov dl, byte [matriz + ecx + 4]
    mov byte [rsi], dl
    inc rsi

    jmp compararSiguienteFilaDecodificar

sigueFilaDecodificar1:
    movzx ecx, byte [posicionLetra1]
    mov dl, byte [matriz + ecx - 1]
    mov byte [rsi], dl
    inc rsi

compararSiguienteFilaDecodificar:
    cmp byte [columna2], 1
    je finDeFilaDecodificar2

    jmp sigueFilaDecodificar2

finDeFilaDecodificar2:
    movzx ecx, byte [posicionLetra2]
    mov dl, byte [matriz + ecx + 4]
    mov byte [rsi], dl
    inc rsi

    jmp decodificarMensaje

sigueFilaDecodificar2:
    movzx ecx, byte [posicionLetra2]
    mov dl, byte [matriz + ecx - 1]
    mov byte [rsi], dl
    inc rsi

    jmp decodificarMensaje

; Si los caracteres se encuentran en la misma columna, tomar el caracter situado arriba.
columnasIgualesDecofidicar:
    cmp byte [fila1], 1
    je finDeColumnaDecodificar1

    jmp sigueColumnaDecodificar1

finDeColumnaDecodificar1:
    movzx ecx, byte [posicionLetra1]
    mov dl, byte [matriz + ecx + 20]
    mov byte [rsi], dl
    inc rsi

    jmp compararSiguienteColumnaDecodificar

sigueColumnaDecodificar1:
    movzx ecx, byte [posicionLetra1]
    mov dl, byte [matriz + ecx - 5]
    mov byte [rsi], dl
    inc rsi

compararSiguienteColumnaDecodificar:
    cmp byte [fila2], 1
    je finDeColumnaDecodificar2

    jmp sigueColumnaDecodificar2

finDeColumnaDecodificar2:
    movzx ecx, byte [posicionLetra2]
    mov dl, byte [matriz + ecx + 20]
    mov byte [rsi], dl
    inc rsi

    jmp decodificarMensaje

sigueColumnaDecodificar2:
    movzx ecx, byte [posicionLetra2]
    mov dl, byte [matriz + ecx - 5]
    mov byte [rsi], dl
    inc rsi

    jmp decodificarMensaje

finDecodificarMensaje:
    ret

; Si los caracteres se encuentran en distinta fila y columna de la matriz, considerar un rectángulo
; formado con los caracteres como vértices y tomar de la misma fila la esquina opuesta.
tomarVertices:
    movzx ecx, byte [posicionLetra1]
    movzx edx, byte [columna1]
    sub ecx, edx
    movzx edx, byte [columna2]
    add ecx, edx
    mov dl, byte [matriz + ecx]
    mov byte [rsi], dl
    inc rsi

    movzx ecx, byte [posicionLetra2]
    movzx edx, byte [columna2]
    sub ecx, edx
    movzx edx, byte [columna1]
    add ecx, edx
    mov dl, byte [matriz + ecx]
    mov byte [rsi], dl
    inc rsi

    ret