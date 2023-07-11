.386
.model flat, stdcall
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;includem biblioteci, si declaram ce functii vrem sa importam
includelib msvcrt.lib
extern exit: proc
extern malloc: proc
extern memset: proc

includelib canvas.lib
extern BeginDrawing: proc
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;declaram simbolul start ca public - de acolo incepe executia
public start
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;sectiunile programului, date, respectiv cod
.data
;aici declaram date
window_title DB "Exemplu proiect desenare",0
area_width EQU 640
area_height EQU 480
area DD 0

counter DD 0 ; numara evenimentele de tip timer

arg1 EQU 8
arg2 EQU 12
arg3 EQU 16
arg4 EQU 20

symbol_width EQU 10
symbol_height EQU 20
include digits.inc
include letters.inc
include X_O2.inc


;dimensiuni tabel
tabel_x EQU 100
tabel_y EQu 100
dimensiune_tabel EQU 135

;dimensiuni buton
buton_x EQU 450
buton_y EQU 150
dimensiune_buton EQU 80

;dimensiuni simbol x si 0
simbol_h EQU 42

;dimensiuni buton restart game
rg_x EQU 450
rg_y EQU 300
dim_rg EQU 80


simbol_color DD 0 ;variabila pt culoarea simbolului
numarator DD 0 ;variabila pt a alege x sau 0 la afisat
ok DD 0

tabel_X_O DD 9 dup(0)


.code
; procedura make_text afiseaza o litera sau o cifra la coordonatele date
; arg1 - simbolul de afisat (litera sau cifra)
; arg2 - pointer la vectorul de pixeli
; arg3 - pos_x
; arg4 - pos_y
make_text proc
	push ebp
	mov ebp, esp
	pusha
	
	mov eax, [ebp+arg1] ; citim simbolul de afisat
	cmp eax, 'A'
	jl make_digit
	cmp eax, 'Z'
	jg make_digit
	sub eax, 'A'
	lea esi, letters
	jmp draw_text
make_digit:
	cmp eax, '0'
	jl make_space
	cmp eax, '9'
	jg make_space
	sub eax, '0'
	lea esi, digits
	jmp draw_text
make_space:	
	mov eax, 26 ; de la 0 pana la 25 sunt litere, 26 e space
	lea esi, letters
	
draw_text:
	mov ebx, symbol_width
	mul ebx
	mov ebx, symbol_height
	mul ebx
	add esi, eax
	mov ecx, symbol_height
bucla_simbol_linii:
	mov edi, [ebp+arg2] ; pointer la matricea de pixeli
	mov eax, [ebp+arg4] ; pointer la coord y
	add eax, symbol_height
	sub eax, ecx
	mov ebx, area_width
	mul ebx
	add eax, [ebp+arg3] ; pointer la coord x
	shl eax, 2 ; inmultim cu 4, avem un DWORD per pixel
	add edi, eax
	push ecx
	mov ecx, symbol_width
bucla_simbol_coloane:
	cmp byte ptr [esi], 0
	je simbol_pixel_alb
	mov dword ptr [edi], 0
	jmp simbol_pixel_next
simbol_pixel_alb:
	mov dword ptr [edi], 0FFFFFFh
simbol_pixel_next:
	inc esi
	add edi, 4
	loop bucla_simbol_coloane
	pop ecx
	loop bucla_simbol_linii
	popa
	mov esp, ebp
	pop ebp
	ret
make_text endp

; un macro ca sa apelam mai usor desenarea simbolului
make_text_macro macro symbol, drawArea, x, y
	push y
	push x
	push drawArea
	push symbol
	call make_text
	add esp, 16
endm

afisare_simbol proc    ;afisam simblurile de x si o
	push ebp
	mov ebp, esp
	pusha
	
	deseneaza_X:
				mov eax, [ebp+arg1]
				cmp eax, 'X'
				jne deseneaza_0
				sub eax, 'X'
				lea esi, X_O2
				mov simbol_color, 0FF0000h ;alegem culoarea pt x
				jmp draw_simbol
	
				
	deseneaza_0:
				mov eax, 1
				mov simbol_color, 00000FFh ;alegem culoarea pt 0
				lea esi, X_O2
	
	draw_simbol:
				mov ebx, 42
				mul ebx
				mov ebx, 42
				mul ebx
				add esi, eax
				mov ecx, 42

	bucla_simbol_linii_xsi0:
						mov edi, [ebp+arg2] ; pointer la matricea de pixeli
						mov eax, [ebp+arg4] ; pointer la coord y
						add eax, 42
						sub eax, ecx
						mov ebx, area_width
						mul ebx
						add eax, [ebp+arg3] ; pointer la coord x
						shl eax, 2 ; inmultim cu 4, avem un DWORD per pixel
						add edi, eax
						push ecx
						mov ecx, 42
	bucla_simbol_coloane_xsi0:
						cmp byte ptr [esi], 0
						je simbol_pixel_alb_xsi0
						mov edx, simbol_color
						mov dword ptr [edi], 0
						jmp simbol_pixel_next_xsi0
	simbol_pixel_alb_xsi0:
					mov dword ptr [edi], 00000ffh
simbol_pixel_next_xsi0:
					inc esi
					add edi, 4
					loop bucla_simbol_coloane_xsi0
					pop ecx
					loop bucla_simbol_linii_xsi0
					popa
					mov esp, ebp
					pop ebp
					ret
afisare_simbol endp

deseneaza_x_si_0 macro caracter, arieDesen, x, y
	push y
	push x
	push arieDesen
	push caracter
	call afisare_simbol
	add esp, 16
endm


linie_orizontala macro x, y, lungime, culoare
local loop_linie
	mov eax, y ; EAX = y
	mov ebx, area_width ;mutam in ebx valoarea lui area_width deoarece nu putem inmulti cu o constanta
	mul ebx  ;EAX = y *area_width
	add eax, x ;EAX = y*area_width + x
	shl eax, 2 ;inmultim cu 4 dar folosim shift left deoarece e mai simplu EAX = 4*(y*area_width + x)
	add eax, area
	mov ecx, lungime
	
loop_linie:
	mov dword ptr[eax], culoare
	add eax, 4
	loop loop_linie

endm

linie_verticala macro x, y, lungime, culoare
local loop_linie
	mov eax, y ; EAX = y
	mov ebx, area_width ;mutam in ebx valoarea lui area_width deoarece nu putem inmulti cu o constanta
	mul ebx  ;EAX = y *area_width
	add eax, x ;EAX = y*area_width + x
	shl eax, 2 ;inmultim cu 4 dar folosim shift left deoarece e mai simplu EAX = 4*(y*area_width + x)
	add eax, area
	mov ecx, lungime
	
loop_linie:
	mov dword ptr[eax], culoare
	add eax, 4* area_width
	loop loop_linie

endm



; functia de desenare - se apeleaza la fiecare click
; sau la fiecare interval de 200ms in care nu s-a dat click
; arg1 - evt (0 - initializare, 1 - click, 2 - s-a scurs intervalul fara click, 3 - s-a apasat o tasta)
; arg2 - x (in cazul apasarii unei taste, x contine codul ascii al tastei care a fost apasata)
; arg3 - y
draw proc
	push ebp
	mov ebp, esp
	pusha
	
	mov eax, [ebp+arg1]
	cmp eax, 1
	jz evt_click
	cmp eax, 2
	jz evt_timer ; nu s-a efectuat click pe nimic
	;mai jos e codul care intializeaza fereastra cu pixeli albi
	cmp eax, 3
	jz evt_timer
	mov eax, area_width
	mov ebx, area_height
	mul ebx
	shl eax, 2
	push eax
	push 255
	push area
	call memset
	add esp, 12
	jmp afisare_litere
	
	
evt_click:
		
		;verific daca am apasat pe buton
	mov eax, [ebp+arg2]  
	cmp eax, buton_x  ;verificam daca apasam click in stanga butonului
	jl square_1
	cmp eax, buton_x + dimensiune_buton ;verificam daca am apasat in dreapta butonului
	jg square_1
	mov eax, [ebp + arg3]
	cmp eax, buton_y   ;verificam daca am apasat deasupra butonului
	jl square_1
	cmp eax, buton_y + dimensiune_buton    ; vad daca am apasat sub buton
	jg square_1 
	;verif_patratel tabel_x, tabel_y, dimensiune_tabel ;verificare daca am apasat in primul patratel
	;s-a dat click pe buton
	

	
	
	;facem tabelul pentru x si 0
	
	;prima linie
	linie_orizontala tabel_x, tabel_y, dimensiune_tabel, 0FF00h
	linie_orizontala tabel_x, tabel_y+1, dimensiune_tabel, 0FF00h
	linie_orizontala tabel_x, tabel_y+2, dimensiune_tabel, 0FF00h
	
	
	;a doua linie
	linie_orizontala tabel_x, tabel_y + dimensiune_tabel / 3 , dimensiune_tabel, 0FF00h
	linie_orizontala tabel_x, tabel_y + dimensiune_tabel / 3 + 1, dimensiune_tabel, 0FF00h
	linie_orizontala tabel_x, tabel_y + dimensiune_tabel / 3 + 2, dimensiune_tabel, 0FF00h
	
	;a treia linie
	linie_orizontala tabel_x, tabel_y + dimensiune_tabel /3 * 2, dimensiune_tabel, 0FF00h
	linie_orizontala tabel_x, tabel_y + dimensiune_tabel /3 * 2+1, dimensiune_tabel, 0FF00h
	linie_orizontala tabel_x, tabel_y + dimensiune_tabel /3 * 2+2, dimensiune_tabel, 0FF00h
	
	;a patra linie
	linie_orizontala tabel_x , tabel_y + dimensiune_tabel, dimensiune_tabel, 0FF00h
	linie_orizontala tabel_x , tabel_y + dimensiune_tabel+1, dimensiune_tabel, 0FF00h
	linie_orizontala tabel_x , tabel_y + dimensiune_tabel+2, dimensiune_tabel, 0FF00h
	
	;prima coloana
	linie_verticala tabel_x, tabel_y, dimensiune_tabel  , 0FF00h
	linie_verticala tabel_x+1, tabel_y, dimensiune_tabel, 0FF00h
	linie_verticala tabel_x+2, tabel_y, dimensiune_tabel, 0FF00h
	
	;a patra coloana
	linie_verticala tabel_x + dimensiune_tabel, tabel_y, dimensiune_tabel + 3, 0FF00h
	linie_verticala tabel_x + dimensiune_tabel +1, tabel_y, dimensiune_tabel + 3, 0FF00h
	linie_verticala tabel_x + dimensiune_tabel +2, tabel_y, dimensiune_tabel + 3, 0FF00h
	
	;a doua coloana
	linie_verticala tabel_x + dimensiune_tabel/3, tabel_y, dimensiune_tabel , 0FF00h
	linie_verticala tabel_x + dimensiune_tabel/3 +1, tabel_y, dimensiune_tabel , 0FF00h
	linie_verticala tabel_x + dimensiune_tabel/3 +2, tabel_y, dimensiune_tabel , 0FF00h
	
	;a treia coloana
	linie_verticala tabel_x + dimensiune_tabel/3 * 2, tabel_y, dimensiune_tabel, 0FF00h
	linie_verticala tabel_x + dimensiune_tabel/3 * 2+1, tabel_y, dimensiune_tabel, 0FF00h
	linie_verticala tabel_x + dimensiune_tabel/3 * 2 +2, tabel_y, dimensiune_tabel, 0FF00h
	
	linie_orizontala rg_x, rg_y, dim_rg, 0FF00h
	linie_orizontala rg_x, rg_y + dim_rg, dim_rg, 0FF00h
	linie_verticala rg_x, rg_y, dim_rg  , 0FF00h
	linie_verticala rg_x + dim_rg, rg_y, dim_rg , 0FF00h
	make_text_macro 'R', area, 460-5, 310
	make_text_macro 'E', area, 470-5, 310
	make_text_macro 'S', area, 480-5, 310
	make_text_macro 'T', area, 490-5, 310
	make_text_macro 'A', area, 500-5, 310
	make_text_macro 'R', area, 510-5, 310
	make_text_macro 'T', area, 520-5, 310


	square_1:
			
			mov eax, [ebp+arg2]  
			cmp eax, 103  ;verificam daca apasam click in stanga patratelului
			jl square_2
			cmp eax, 145 ;verificam daca am apasat in dreapta butonului
			jg square_2
			mov eax, [ebp + arg3]
			cmp eax, 103   ;verificam daca am apasat deasupra butonului
			jl square_2
			cmp eax, 145    ; vad daca am apasat sub buton
			jg square_2 
			
			cmp tabel_X_O[0], 0
			jne button_fail
			inc numarator
			xor edx, edx
			mov eax, dword ptr numarator
			mov ecx, 2
			div ecx
			cmp edx, 1
			je impar
			deseneaza_x_si_0 '0', area, 103, 103
			mov tabel_X_O[0], 2
			cmp numarator, 9
			je restart_game
			jmp verify_winner
			jmp button_fail
			
			impar:
				 deseneaza_x_si_0 'X', area, 103, 103
				 mov tabel_X_O[0],1
				 cmp numarator, 9
				 je restart_game
				 jmp verify_winner
			
	
	square_2:
			mov eax, [ebp+arg2]
			cmp eax, 148
			jl square_3
			cmp eax, 191
			jg square_3
			mov eax, [ebp + arg3]
			cmp eax, 103
			jl square_3
			cmp eax, 145
			jg square_3
			 cmp tabel_X_O[4], 0
			jne button_fail
			inc numarator
			xor edx, edx
			mov eax, dword ptr numarator
			mov ecx, 2
			div ecx
			cmp edx, 1
			je impar1
			 deseneaza_x_si_0 '0', area, 148, 103
			 mov tabel_X_O[4], 2
			 cmp numarator, 9
			 je restart_game
			 jmp verify_winner
			 jmp button_fail
			impar1:
				deseneaza_x_si_0 'X', area, 148, 103
				mov tabel_X_O[4], 1
				cmp numarator, 9
				je restart_game
				jmp verify_winner
			
	square_3:
			mov eax, [ebp+arg2]
			cmp eax, 193
			jl square_4
			cmp eax, 235
			jg square_4
			mov eax, [ebp + arg3]
			cmp eax, 103
			jl square_4
			cmp eax, 145
			jg square_4
			 cmp tabel_X_O[8], 0
			 jne button_fail
			inc numarator
			xor edx, edx
			mov eax, dword ptr numarator
			mov ecx, 2
			div ecx
			cmp edx, 1
			je impar2
			deseneaza_x_si_0 '0', area, 193, 103
			mov tabel_X_O[8], 2
			cmp numarator, 9
			je restart_game
			jmp verify_winner
			jmp button_fail
			impar2:
				 deseneaza_x_si_0 'X', area, 193, 103
				 mov tabel_X_O[8], 1
				 cmp numarator, 9
				 je restart_game
				 jmp verify_winner
			
	square_4:
			mov eax, [ebp+arg2]
			cmp eax, 103
			jl square_5
			cmp eax, 145
			jg square_5
			mov eax, [ebp + arg3]
			cmp eax, 148
			jl square_5
			cmp eax, 191
			jg square_5
			 cmp tabel_X_O[12], 0
			 jne button_fail
			inc numarator
			xor edx, edx
			mov eax, dword ptr numarator
			mov ecx, 2
			div ecx
			cmp edx, 1
			je impar3
			 deseneaza_x_si_0 '0', area, 103, 148
			 mov tabel_X_O[12], 2
			 cmp numarator, 9
			 je restart_game
			 jmp verify_winner
			 jmp button_fail
			impar3:
				deseneaza_x_si_0 'X', area, 103, 148
				mov tabel_X_O[12], 1
				cmp numarator, 9
				je restart_game
				jmp verify_winner
			
	
	square_5:
			mov eax, [ebp+arg2]
			cmp eax, 148
			jl square_6
			cmp eax, 191
			jg square_6
			mov eax, [ebp + arg3]
			cmp eax, 148
			jl square_6
			cmp eax, 191
			jg square_6
			 cmp tabel_X_O[16], 0
			 jne button_fail
			inc numarator
			xor edx, edx
			mov eax, dword ptr numarator
			mov ecx, 2
			div ecx
			cmp edx, 1
			je impar4
			 deseneaza_x_si_0 '0', area, 148, 148
			 mov tabel_X_O[16], 2
			 cmp numarator, 9
			 je restart_game
			 jmp verify_winner
			 jmp button_fail
			impar4:
				deseneaza_x_si_0 'X', area, 148, 148
				mov tabel_X_O[16], 1
				cmp numarator, 9
				je restart_game
				jmp verify_winner

			
	square_6:
			mov eax, [ebp+arg2]
			cmp eax, 193
			jl square_7
			cmp eax, 235
			jg square_7
			mov eax, [ebp + arg3]
			cmp eax, 148
			jl square_7
			cmp eax, 191
			jg square_7
			
			
			 cmp tabel_X_O[20], 0
			 jne button_fail
			
			inc numarator
			xor edx, edx
			mov eax, dword ptr numarator
			mov ecx, 2
			div ecx
			cmp edx, 1
			je impar5
			 deseneaza_x_si_0 '0', area, 193, 148
			 mov tabel_X_O[20], 2
			 cmp numarator, 9
			 je restart_game
			 jmp verify_winner
			 jmp button_fail
			impar5:
				deseneaza_x_si_0 'X', area, 193, 148
				mov tabel_X_O[20], 1
				cmp numarator, 9
				je restart_game
				jmp verify_winner
			
	
	square_7:
			mov eax, [ebp+arg2]
			cmp eax, 103
			jl square_8
			cmp eax, 145
			jg square_8
			mov eax, [ebp + arg3]
			cmp eax, 193
			jl square_8
			cmp eax, 235
			jg square_8
			
			
			 cmp tabel_X_O[24], 0
			 jne button_fail
			
			inc numarator
			xor edx, edx
			mov eax, dword ptr numarator
			mov ecx, 2
			div ecx
			cmp edx, 1
			je impar6
			 deseneaza_x_si_0 '0', area, 103, 193
			 mov tabel_X_O[24], 2
			 cmp numarator, 9
			 je restart_game
			 jmp verify_winner
			 jmp button_fail
			impar6:
				deseneaza_x_si_0 'X', area, 103, 193
				mov tabel_X_O[24], 1
				cmp numarator, 9
			    je restart_game
				jmp verify_winner
			
	
	square_8:
			mov eax, [ebp+arg2]
			cmp eax, 148
			jl square_9
			cmp eax, 191
			jg square_9
			mov eax, [ebp + arg3]
			cmp eax, 193
			jl square_9
			cmp eax, 235
			jg square_9
			
			
			 cmp tabel_X_O[28], 0
			 jne button_fail
			
			inc numarator
			xor edx, edx
			mov eax, dword ptr numarator
			mov ecx, 2
			div ecx
			cmp edx, 1
			je impar7
			 deseneaza_x_si_0 '0', area, 148, 193
			 mov tabel_X_O[28], 2
			 cmp numarator, 9
			 je restart_game
			 jmp verify_winner
			 jmp button_fail
			impar7:
				deseneaza_x_si_0 'X', area, 148, 193
				mov tabel_X_O[28], 1
				cmp numarator, 9
				je restart_game
				jmp verify_winner
			
	

	square_9:
			mov eax, [ebp+arg2]
			cmp eax, 193
			jl play_again
			cmp eax, 235
			jg play_again
			mov eax, [ebp + arg3]
			cmp eax, 193
			jl play_again
			cmp eax, 235
			jg play_again
			
			mov edx, tabel_X_O[32]
			 cmp tabel_X_O[32], 0
			 jne button_fail
			
			inc numarator
			xor edx, edx
			mov eax, dword ptr numarator
			mov ecx, 2
			div ecx
			cmp edx, 1
			je impar8
			 deseneaza_x_si_0 '0', area, 193, 193
			 mov tabel_X_O[32], 2
			 cmp numarator, 9
			 je restart_game
			 jmp verify_winner
			 jmp button_fail
			impar8:
				deseneaza_x_si_0 'X', area, 193, 193
				mov tabel_X_O[32], 1
				cmp numarator, 9
				je restart_game
				jmp verify_winner

	jmp afisare_litere
	
restart_game:
	linie_orizontala rg_x, rg_y, dim_rg, 0FF00h
	linie_orizontala rg_x, rg_y + dim_rg, dim_rg, 0FF00h
	linie_verticala rg_x, rg_y, dim_rg  , 0FF00h
	linie_verticala rg_x + dim_rg, rg_y, dim_rg , 0FF00h
	make_text_macro 'R', area, 460-5, 310
	make_text_macro 'E', area, 470-5, 310
	make_text_macro 'S', area, 480-5, 310
	make_text_macro 'T', area, 490-5, 310
	make_text_macro 'A', area, 500-5, 310
	make_text_macro 'R', area, 510-5, 310
	make_text_macro 'T', area, 520-5, 310
	jmp verify_winner

play_again:
	mov eax, [ebp+arg2]  
	cmp eax, rg_x  ;verificam daca apasam click in stanga butonului
	jl button_fail
	cmp eax, rg_x + dim_rg ;verificam daca am apasat in dreapta butonului
	jg button_fail
	mov eax, [ebp + arg3]
	cmp eax, rg_y   ;verificam daca am apasat deasupra butonului
	jl button_fail
	cmp eax, rg_y + dim_rg    ; vad daca am apasat sub buton
	jg button_fail
	mov eax, area_width
	mov ebx, area_height
	mul ebx
	shl eax, 2
	push eax
	push 0FFFFFFh
	push area
	call memset
	add esp, 12
	mov numarator, 0
	
	mov ecx, 9
	bucla_make_matrice_0:
		mov esi, ecx
		dec esi
		mov tabel_X_O[esi * 4], 0
	loop bucla_make_matrice_0
	
	jmp restart_game

jmp afisare_litere	

verify_winner:
	verify_first_column:
		mov ecx, tabel_X_O[0]
		mov ebx, tabel_X_O[12]
		mov eax, tabel_X_O[24]
		cmp ecx, ebx
		jne verify_second_column
		cmp ecx, eax
		jne verify_second_column
		cmp eax, ebx
		jne verify_second_column
		cmp eax, 1
		je player_X_winner
		cmp eax, 2
		je player_0_winner
		
	
	verify_second_column:
		mov ecx, tabel_X_O[4]
		mov ebx, tabel_X_O[16]
		mov eax, tabel_X_O[28]
		cmp ecx, ebx
		jne verify_third_column
		cmp ecx, eax
		jne verify_third_column
		cmp eax, ebx
		jne verify_third_column
		cmp eax, 1
		je player_X_winner
		cmp eax, 2
		je player_0_winner
	
	verify_third_column:
		mov ecx, tabel_X_O[8]
		mov ebx, tabel_X_O[20]
		mov eax, tabel_X_O[32]
		cmp ecx, ebx
		jne verify_first_line
		cmp ecx, eax
		jne verify_first_line
		cmp eax, ebx
		jne verify_first_line
		cmp eax, 1
		je player_X_winner
		cmp eax, 2
		je player_0_winner
		
	verify_first_line:
		mov ecx, tabel_X_O[0]
		mov ebx, tabel_X_O[4]
		mov eax, tabel_X_O[8]
		cmp ecx, ebx
		jne verify_second_line
		cmp ecx, eax
		jne verify_second_line
		cmp eax, ebx
		jne verify_second_line
		cmp eax, 1
		je player_X_winner
		cmp eax, 2
		je player_0_winner
		
	verify_second_line:
		mov ecx, tabel_X_O[12]
		mov ebx, tabel_X_O[16]
		mov eax, tabel_X_O[20]
		cmp ecx, ebx
		jne verify_third_line
		cmp ecx, eax
		jne verify_third_line
		cmp eax, ebx
		jne verify_third_line
		cmp eax, 1
		je player_X_winner
		cmp eax, 2
		je player_0_winner
		
	verify_third_line:
		mov ecx, tabel_X_O[24]
		mov ebx, tabel_X_O[28]
		mov eax, tabel_X_O[32]
		cmp ecx, ebx
		jne verify_first_diagonal
		cmp ecx, eax
		jne verify_first_diagonal
		cmp eax, ebx
		jne verify_first_diagonal
		cmp eax, 1
		je player_X_winner
		cmp eax, 2
		je player_0_winner
	
	verify_first_diagonal:
		mov ecx, tabel_X_O[0]
		mov ebx, tabel_X_O[16]
		mov eax, tabel_X_O[32]
		cmp ecx, ebx
		jne verify_second_diagonal
		cmp ecx, eax
		jne verify_second_diagonal
		cmp eax, ebx
		jne verify_second_diagonal
		cmp eax, 1
		je player_X_winner
		cmp eax, 2
		je player_0_winner
		
	verify_second_diagonal:
		mov ecx, tabel_X_O[8]
		mov ebx, tabel_X_O[16]
		mov eax, tabel_X_O[24]
		cmp ecx, ebx
		jne verify_tie
		cmp ecx, eax
		jne verify_tie
		cmp eax, ebx
		jne verify_tie
		cmp eax, 1
		je player_X_winner
		cmp eax, 2
		je player_0_winner
	
	verify_tie:
		mov eax, numarator
		cmp eax, 9
		je remiza
jmp afisare_litere

player_X_winner:
	make_text_macro 'P', area, 100, 300
	make_text_macro 'L', area, 110, 300
	make_text_macro 'A', area, 120, 300
	make_text_macro 'Y', area, 130, 300
	make_text_macro 'E', area, 140, 300
	make_text_macro 'R', area, 150, 300
	make_text_macro ' ', area, 160, 300
	make_text_macro 'X', area, 170, 300
	make_text_macro ' ', area, 180, 300
	make_text_macro 'W', area, 190, 300
	make_text_macro 'I', area, 200, 300
	make_text_macro 'N', area, 210, 300
	jmp play_again
	jmp afisare_litere
	
player_0_winner:
	make_text_macro 'P', area, 100, 300
	make_text_macro 'L', area, 110, 300
	make_text_macro 'A', area, 120, 300
	make_text_macro 'Y', area, 130, 300
	make_text_macro 'E', area, 140, 300
	make_text_macro 'R', area, 150, 300
	make_text_macro ' ', area, 160, 300
	make_text_macro '0', area, 170, 300
	make_text_macro ' ', area, 180, 300
	make_text_macro 'W', area, 190, 300
	make_text_macro 'I', area, 200, 300
	make_text_macro 'N', area, 210, 300
	jmp play_again
	jmp afisare_litere
	
remiza:
	make_text_macro 'R', area, 100, 300
	make_text_macro 'E', area, 110, 300
	make_text_macro 'M', area, 120, 300
	make_text_macro 'I', area, 130, 300
	make_text_macro 'Z', area, 140, 300
	make_text_macro 'A', area, 150, 300
     jmp play_again                          

jmp afisare_litere	
	                           
button_fail:                   
	                           
	jmp afisare_litere         
	
evt_timer:
	inc counter
	
	
afisare_litere:
	;afisam valoarea counter-ului curent (sute, zeci si unitati)
	mov ebx, 10
	mov eax, counter
	;cifra unitatilor
	mov edx, 0
	div ebx
	add edx, '0'
	make_text_macro edx, area, 30, 10
	;cifra zecilor
	mov edx, 0
	div ebx
	add edx, '0'
	make_text_macro edx, area, 20, 10
	;cifra sutelor
	mov edx, 0
	div ebx
	add edx, '0'
	make_text_macro edx, area, 10, 10
	
	
	;scriem un mesaj
	make_text_macro 'T', area, 270, 60
	make_text_macro 'I', area, 280, 60
	make_text_macro 'C', area, 290, 60
	make_text_macro 'T', area, 310, 60
	make_text_macro 'A', area, 320, 60
	make_text_macro 'C', area, 330, 60
	make_text_macro 'T', area, 350, 60
	make_text_macro 'O', area, 360, 60
	make_text_macro 'E', area, 370, 60
	
	;buton
	linie_orizontala buton_x, buton_y, dimensiune_buton, 0FF00h
	linie_orizontala buton_x, buton_y + dimensiune_buton, dimensiune_buton, 0FF00h
	linie_verticala buton_x, buton_y, dimensiune_buton  , 0FF00h
	linie_verticala buton_x + dimensiune_buton, buton_y, dimensiune_buton  , 0FF00h
	
	;mesajul butonului
	make_text_macro 'S', area, 460, 160
	make_text_macro 'T', area, 470, 160
	make_text_macro 'A', area, 480, 160
	make_text_macro 'R', area, 490, 160
	make_text_macro 'T', area, 500, 160
	
	make_text_macro 'G', area, 460, 180
	make_text_macro 'A', area, 470, 180
	make_text_macro 'M', area, 480, 180
	make_text_macro 'E', area, 490, 180
	
	make_text_macro 'M', area, 110, 400
	make_text_macro 'E', area, 120, 400
	make_text_macro 'D', area, 130, 400
	make_text_macro 'V', area, 140, 400
	make_text_macro 'I', area, 150, 400
	make_text_macro 'C', area, 160, 400
	make_text_macro 'H', area, 170, 400
	make_text_macro 'I', area, 180, 400
	make_text_macro 'F', area, 200, 400
	make_text_macro 'L', area, 210, 400
	make_text_macro 'A', area, 220, 400
	make_text_macro 'V', area, 230, 400
	make_text_macro 'I', area, 240, 400
	make_text_macro 'A', area, 250, 400
	make_text_macro 'N', area, 260, 400
	
	
	
		

final_draw:
	popa
	mov esp, ebp
	pop ebp
	ret
draw endp

start:
	;alocam memorie pentru zona de desenat
	mov eax, area_width
	mov ebx, area_height
	mul ebx
	shl eax, 2
	push eax
	call malloc
	add esp, 4
	mov area, eax
	;apelam functia de desenare a ferestrei
	; typedef void (*DrawFunc)(int evt, int x, int y);
	; void __cdecl BeginDrawing(const char *title, int width, int height, unsigned int *area, DrawFunc draw);
	push offset draw
	push area
	push area_height
	push area_width
	push offset window_title
	call BeginDrawing
	add esp, 20
	
	;terminarea programului
	push 0
	call exit
end start
