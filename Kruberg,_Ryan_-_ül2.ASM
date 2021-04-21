; --! Klaviatuuri katkestusvektor protseduuri asukohta on vajalik lisada
;	Muidu klaviatuuri sisestus ülekirjutab mälu [BF]st [00]ni
; -@- VDU = Virtual Display Unit

; CL on kasutusel, et kontrollida, mitu tähte võib veel sisestada
;	ei arvesta rea limiidiga (16)
; DL on VDU mälupointerina kasutusel
; 	VDUl on 16 tulpa, ning 4 rida. 
;	VDU poolt reserveeritud mäluala ON [C0] kuni [FF] k.a.

	JMP	alusta	; Vajalik hüpata, et byte saaks defineerida

; ===== Salvestab asju mällu ===================================================
; ===== Katkestusvektorite salvestamine, katkestusvektorite mälukoht on tähtis -
	DB	0F	; Riistvara katkestusvektor			[02]
	DB	00	; Klaviatuuri katkestusvektor			[03]
	DB	20	; Numbriklahvistiku katkestusvektor		[04]
; ===== Parameetrite salvestamine --------------------------------------------==
	DB	5F	; VDU tühja numbri koht; _ (ASCII) 		[05]
	DB	02	; Maksimaalne sisendi suurus			[06]
	DB	00	; Vastus numbrina visuaalselt HEXi kujul	[07]

; ===== Lisab VDU esimesele reale "Sisend:__" --------------------------------==
	ORG	C0	
	DB	"S"
; ----- Kasutan pikemat viisi, et väikseid tähti näidata
	DB	69	; = "i" (ASCII)
	DB	73	; = "s" (ASCII)
	DB	65	; = "e" (ASCII)
	DB	6E	; = "n" (ASCII)
	DB	64	; = "d" (ASCII)
	DB	":__"	; 2 kohta sisendiks
; ===== Lisab VDU teisele reale "Vastus:______" ------------------------------==
	ORG	D0	; VDU teise rea algus
	DB	"V"
; ----- Kasutan pikemat viisi, et väikseid tähti näidata
	DB	61	; = "a" (ASCII)
	DB	73	; = "s" (ASCII)
	DB	74	; = "t" (ASCII)
	DB	75	; = "u" (ASCII)
	DB	73	; = "s" (ASCII)
	DB	":_______"  
; -- 7 kohta vastuseks, sest kahekohaline arv kümnendsüsteemis
; -- võtab maksimaalselt 7 kohta binaarsüsteemis
; ==============================================================================


; ===== Klaviatuuri katkestusvektor ============================================
; -- Kuigi siin midagi ei toimu, on see töötamiseks vajalik --------------------
	ORG	0F
	IRET		; Jätkab koodi kust katkestati
; ==============================================================================

; ===== Asenda eelmist sisendit ================================================
	ORG	10	; Napilt mahub mällu -----------------------------------
	PUSH	AL	; Salvestab sisendi mällu
	DEC	DL	; Pointer eelmise sisendi peale
	MOV	BL, [DL]; BL = [DL] (Eelmise sisendi kopeerimine BL-i)

	MOV	AL, [05]; AL = VDU tühja numbri karakter
	MOV	[DL], AL; [DL] = AL (Eelmise sisendi asendus)
	POP	AL	; Taastab sisendi mälust
	RET		; Läheb tagasi sinna, kust kutsuti
; ==============================================================================

; ===== Sisendiga tegelev protseduur ===========================================
	ORG	20
	CLI		; Keelab segamist
	IN	08	; AL << Klaviatuuri sisend
; ===== Sisendi kustutamise ala ----------------------------------------------==
; ----- Tegeleb backspacega ----------------------------------------------------
	CMP	AL, 08	; 08 = backspace (ASCII)
	JZ	bak	; Kui vajutati backspace, siis kustuta viimane sisestus
	CMP	AL, 43	; Kontrollib, kas taheti kustutada kõik
	JZ	bak	; Läheb kustutama | Kordab kuni kõik tähed kustutatud
; ----- Kontrollib, kas enam tähti ei või sisestada ----------------------------
	CMP	CL, 00	; Kontrollib, kas lubatud sisestuste arv = 0
	JZ	valmis	; Kui võrdub, siis arv on valmis teisendamiseks
; ------------------------------------------------------------------------------
; ===== Numbriga tegelev osa -------------------------------------------------==
; ----- Kontrollib, kas on number - 29 < AL < 3A -------------------------------
	CMP	AL,3A	; 3A = "9" (ASCII)
	JNS     stop	; Eira sisestust kui 3A < AL | 9st edaspidised tähed
	CMP	AL,30  	; 30 = "0" (ASCII)
	JS 	stop	; Eira sisestust kui AL	< 30 | 0st eelnevad tähed
; ----- Salvestab sisendi kui on -----------------------------------------------
	MOV	[DL], AL; Asendab mälukoha AL-iga
	INC	DL	; Suurendab VDU pointerit
	DEC	CL	; Vähendab palju tähti võib veel lisada (1 võrra)
	JMP 	stop	; Kui ei või enam tähti lisada, eirab sisendit
; ------------------------------------------------------------------------------
; ===== Labelid --------------------------------------------------------------==
; -- Labelite järjekord on mälu säästmiseks tähtis -----------------------------
bak:
; ----- Kontrollib, kas peaks kustutama, arvestades sisestatud tähtede arvu ----
; -- if max != current then do it-----------------------------------------------
	CMP	CL, [06]; Kontrollib kas tähti on sisestatud
	JZ	stop	; Kui pole, eira sisestust
; ----- Asendab eelmise tähe ---------------------------------------------------
	INC	CL	; Suurendab palju tähti võib veel lisada (1 võrra)
	CALL	10	; Asenda eelmine sisend AL-iga, ning BL = Eelmine sisend
; ----- Kui kasutaja tahtis kõik kustutada, vajutas C tähte, siis kordab -------
	CMP	AL, 43	; Kontrollib, kas taheti kustutada kõik
	JZ	bak	; Kordab kuni kõik tähed kustutatud
valmis:
	CMP	AL, 0D	; 0D = CR (ASCII) | Kontrollib kas kasutaja on valmis
	JNZ	stop	; Kui kasutaja pole valmis, siis ära teisenda arvu
	PUSH	DL	; Jätab sisendi pointeri meelde
	CALL	75	; Sisendi teisendamine 
	POP	DL	; Taastab sisendi pointeri
stop:
	STI		; Lubab segamist
	IRET		; Jätkab koodi kust katkestati
; ==============================================================================

; ===== Teisendamine ja tulemuse näitamine =====================================
	ORG	75
; ----- Sisendi laadimine protsessori mällu ------------------------------------
	MOV	AL, [C7]; AL = kümnendiku kohal olev number 	(AL xx)
	MOV	BL, [C8]; BL = ühendiku kohal olev number 	(xx BL)
; ----- Sisendite muutmine numbriks --------------------------------------------
	SUB	AL, 30	; Muudab ASCII tähe numbriks
	SUB	BL, 30	; Muudab ASCII tähe numbriks
	MUL	AL, A	; AL *= 10 (10nd süsteemis)
	ADD	AL, BL	; Saan sisendi 16ndik süsteemis
; ----- Sisendite muutmine ja näitamine binaarsüsteemis ------------------------
	MOV	[07], AL
	MOV	BL, 40
	MOV	DL, D7
rep:
	AND	AL, BL
	JZ	_0
	MOV	AL, 01
	JNZ	print
_0:	
	MOV	AL, 00
print:
	ADD	AL, 30
	MOV	[DL],AL
	INC	DL

	MOV	AL, [07]
	SHR	BL
	JNZ	rep
	RET
; ==============================================================================


; ===== Peakood ================================================================
	ORG	60	; Paneb peakoodi u. mälu keskele
alusta:
	CLO		; Sulgeb kõik aknad
; ----- Ülekirjutab eelmise sisendi --------------------------------------------
;	Eelmine sisend jäi mällu, kui SMZ programmis RUN vajutasin
;	Järgmine osa on selle tüütuse lahendamiseks tehtud
	MOV	DL, [06]; DL = max sisendi suurus
	ADD	DL, C7	; DL += koht peale "Sisend:"
	MOV	AL, 43	; AL = "C", käseb "bak"-il puhastada terve sisend
	CALL	4A	; Kutsub "bak"-i (backspace-ga tegelev osa)| [] = INC !!
; ------------------------------------------------------------------------------
	OUT	08	; Toob numberklahvid välja
	STI		; Lubab segamist - et klaviatuuri sündmustega tegeleda
idle:	
	NOP
	JMP	idle	; Hoiab programmi tsüklis
; ------------------------------------------------------------------------------
	END


