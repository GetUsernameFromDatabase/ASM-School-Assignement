; --! Klaviatuuri katkestusvektor protseduuri asukohta on vajalik lisada
;	Muidu klaviatuuri sisestus �lekirjutab m�lu [BF]st [00]ni
; -@- VDU = Virtual Display Unit

; CL on kasutusel, et kontrollida, mitu t�hte v�ib veel sisestada
;	ei arvesta rea limiidiga (16)
; DL on VDU m�lupointerina kasutusel
; 	VDUl on 16 tulpa, ning 4 rida. 
;	VDU poolt reserveeritud m�luala ON [C0] kuni [FF] k.a.

	JMP	alusta	; Vajalik h�pata, et byte saaks defineerida

; ===== Salvestab asju m�llu ===================================================
; ===== Katkestusvektorite salvestamine, katkestusvektorite m�lukoht on t�htis -
	DB	0F	; Riistvara katkestusvektor			[02]
	DB	00	; Klaviatuuri katkestusvektor			[03]
	DB	20	; Numbriklahvistiku katkestusvektor		[04]
; ===== Parameetrite salvestamine --------------------------------------------==
	DB	5F	; VDU t�hja numbri koht; _ (ASCII) 		[05]
	DB	02	; Maksimaalne sisendi suurus			[06]
	DB	00	; Vastus numbrina visuaalselt HEXi kujul	[07]

; ===== Lisab VDU esimesele reale "Sisend:__" --------------------------------==
	ORG	C0	
	DB	"S"
; ----- Kasutan pikemat viisi, et v�ikseid t�hti n�idata
	DB	69	; = "i" (ASCII)
	DB	73	; = "s" (ASCII)
	DB	65	; = "e" (ASCII)
	DB	6E	; = "n" (ASCII)
	DB	64	; = "d" (ASCII)
	DB	":__"	; 2 kohta sisendiks
; ===== Lisab VDU teisele reale "Vastus:______" ------------------------------==
	ORG	D0	; VDU teise rea algus
	DB	"V"
; ----- Kasutan pikemat viisi, et v�ikseid t�hti n�idata
	DB	61	; = "a" (ASCII)
	DB	73	; = "s" (ASCII)
	DB	74	; = "t" (ASCII)
	DB	75	; = "u" (ASCII)
	DB	73	; = "s" (ASCII)
	DB	":_______"  
; -- 7 kohta vastuseks, sest kahekohaline arv k�mnends�steemis
; -- v�tab maksimaalselt 7 kohta binaars�steemis
; ==============================================================================


; ===== Klaviatuuri katkestusvektor ============================================
; -- Kuigi siin midagi ei toimu, on see t��tamiseks vajalik --------------------
	ORG	0F
	IRET		; J�tkab koodi kust katkestati
; ==============================================================================

; ===== Asenda eelmist sisendit ================================================
	ORG	10	; Napilt mahub m�llu -----------------------------------
	PUSH	AL	; Salvestab sisendi m�llu
	DEC	DL	; Pointer eelmise sisendi peale
	MOV	BL, [DL]; BL = [DL] (Eelmise sisendi kopeerimine BL-i)

	MOV	AL, [05]; AL = VDU t�hja numbri karakter
	MOV	[DL], AL; [DL] = AL (Eelmise sisendi asendus)
	POP	AL	; Taastab sisendi m�lust
	RET		; L�heb tagasi sinna, kust kutsuti
; ==============================================================================

; ===== Sisendiga tegelev protseduur ===========================================
	ORG	20
	CLI		; Keelab segamist
	IN	08	; AL << Klaviatuuri sisend
; ===== Sisendi kustutamise ala ----------------------------------------------==
; ----- Tegeleb backspacega ----------------------------------------------------
	CMP	AL, 08	; 08 = backspace (ASCII)
	JZ	bak	; Kui vajutati backspace, siis kustuta viimane sisestus
	CMP	AL, 43	; Kontrollib, kas taheti kustutada k�ik
	JZ	bak	; L�heb kustutama | Kordab kuni k�ik t�hed kustutatud
; ----- Kontrollib, kas enam t�hti ei v�i sisestada ----------------------------
	CMP	CL, 00	; Kontrollib, kas lubatud sisestuste arv = 0
	JZ	valmis	; Kui v�rdub, siis arv on valmis teisendamiseks
; ------------------------------------------------------------------------------
; ===== Numbriga tegelev osa -------------------------------------------------==
; ----- Kontrollib, kas on number - 29 < AL < 3A -------------------------------
	CMP	AL,3A	; 3A = "9" (ASCII)
	JNS     stop	; Eira sisestust kui 3A < AL | 9st edaspidised t�hed
	CMP	AL,30  	; 30 = "0" (ASCII)
	JS 	stop	; Eira sisestust kui AL	< 30 | 0st eelnevad t�hed
; ----- Salvestab sisendi kui on -----------------------------------------------
	MOV	[DL], AL; Asendab m�lukoha AL-iga
	INC	DL	; Suurendab VDU pointerit
	DEC	CL	; V�hendab palju t�hti v�ib veel lisada (1 v�rra)
	JMP 	stop	; Kui ei v�i enam t�hti lisada, eirab sisendit
; ------------------------------------------------------------------------------
; ===== Labelid --------------------------------------------------------------==
; -- Labelite j�rjekord on m�lu s��stmiseks t�htis -----------------------------
bak:
; ----- Kontrollib, kas peaks kustutama, arvestades sisestatud t�htede arvu ----
; -- if max != current then do it-----------------------------------------------
	CMP	CL, [06]; Kontrollib kas t�hti on sisestatud
	JZ	stop	; Kui pole, eira sisestust
; ----- Asendab eelmise t�he ---------------------------------------------------
	INC	CL	; Suurendab palju t�hti v�ib veel lisada (1 v�rra)
	CALL	10	; Asenda eelmine sisend AL-iga, ning BL = Eelmine sisend
; ----- Kui kasutaja tahtis k�ik kustutada, vajutas C t�hte, siis kordab -------
	CMP	AL, 43	; Kontrollib, kas taheti kustutada k�ik
	JZ	bak	; Kordab kuni k�ik t�hed kustutatud
valmis:
	CMP	AL, 0D	; 0D = CR (ASCII) | Kontrollib kas kasutaja on valmis
	JNZ	stop	; Kui kasutaja pole valmis, siis �ra teisenda arvu
	PUSH	DL	; J�tab sisendi pointeri meelde
	CALL	75	; Sisendi teisendamine 
	POP	DL	; Taastab sisendi pointeri
stop:
	STI		; Lubab segamist
	IRET		; J�tkab koodi kust katkestati
; ==============================================================================

; ===== Teisendamine ja tulemuse n�itamine =====================================
	ORG	75
; ----- Sisendi laadimine protsessori m�llu ------------------------------------
	MOV	AL, [C7]; AL = k�mnendiku kohal olev number 	(AL xx)
	MOV	BL, [C8]; BL = �hendiku kohal olev number 	(xx BL)
; ----- Sisendite muutmine numbriks --------------------------------------------
	SUB	AL, 30	; Muudab ASCII t�he numbriks
	SUB	BL, 30	; Muudab ASCII t�he numbriks
	MUL	AL, A	; AL *= 10 (10nd s�steemis)
	ADD	AL, BL	; Saan sisendi 16ndik s�steemis
; ----- Sisendite muutmine ja n�itamine binaars�steemis ------------------------
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
	ORG	60	; Paneb peakoodi u. m�lu keskele
alusta:
	CLO		; Sulgeb k�ik aknad
; ----- �lekirjutab eelmise sisendi --------------------------------------------
;	Eelmine sisend j�i m�llu, kui SMZ programmis RUN vajutasin
;	J�rgmine osa on selle t��tuse lahendamiseks tehtud
	MOV	DL, [06]; DL = max sisendi suurus
	ADD	DL, C7	; DL += koht peale "Sisend:"
	MOV	AL, 43	; AL = "C", k�seb "bak"-il puhastada terve sisend
	CALL	4A	; Kutsub "bak"-i (backspace-ga tegelev osa)| [] = INC !!
; ------------------------------------------------------------------------------
	OUT	08	; Toob numberklahvid v�lja
	STI		; Lubab segamist - et klaviatuuri s�ndmustega tegeleda
idle:	
	NOP
	JMP	idle	; Hoiab programmi ts�klis
; ------------------------------------------------------------------------------
	END


