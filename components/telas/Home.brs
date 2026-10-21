' VLTV Play - Roku | Home: menu, destaque (Top 10 da VPS), avisos de vencimento e campanha.

sub iniciar()
    carregarI18n()
    m.slides = []
    m.pos = 0
    uiRet(m.top, 0, 0, 1920, 1080, uiFundo())
    uiFoto(m.top, 70, 36, 84, 84, "pkg:/images/logo.png", false)
    uiLinha(m.top, 170, 52, 700, "VLTV Play", "font:LargeBoldSystemFont", uiTexto())
    m.hora = uiNo(m.top, "Label", { translation: [1500, 52], width: 350, horizAlign: "right", font: "font:LargeSystemFont", color: uiTexto() })
    m.licTxt = uiNo(m.top, "Label", { translation: [1000, 100], width: 850, horizAlign: "right", font: "font:SmallSystemFont", color: uiSuave() })

    m.faixa = uiRet(m.top, 70, 140, 1780, 56, "0x1E1E22FF")
    m.faixaCor = uiRet(m.top, 70, 140, 8, 56, uiDestaque())
    m.faixaTxt = uiNo(m.top, "Label", { translation: [96, 150], width: 1740, font: "font:SmallSystemFont", color: uiTexto() })
    m.faixa.visible = false
    m.faixaCor.visible = false

    m.menu = uiLista(m.top, 70, 250, 520, 5, 96)
    m.menu.content = uiItensLista(["TV ao Vivo", "Filmes", "Séries", "Minhas listas", "Configurações"])
    m.menu.observeField("itemSelected", "aoMenu")

    m.capa = uiFoto(m.top, 700, 240, 320, 480, "", true)
    m.etiqueta = uiNo(m.top, "Label", { translation: [1070, 250], width: 780, font: "font:SmallBoldSystemFont", color: uiDestaque() })
    m.nome = uiNo(m.top, "Label", { translation: [1070, 300], width: 780, height: 200, wrap: true, maxLines: 3, font: "font:LargeBoldSystemFont", color: uiTexto() })
    m.meta = uiNo(m.top, "Label", { translation: [1070, 520], width: 780, font: "font:MediumSystemFont", color: uiSuave() })
    m.bt = uiBotoes(m.top, 1070, 600, ["Ver detalhes"], false)
    m.bt.observeField("buttonSelected", "aoDestaque")
    m.pontos = uiNo(m.top, "Label", { translation: [700, 740], width: 1150, font: "font:SmallSystemFont", color: uiSuave() })

    m.relogio = uiNo(m.top, "Timer", { repeat: true, duration: 20 })
    m.relogio.observeField("fire", "tique")
    m.relogio.control = "start"
    m.giro = uiNo(m.top, "Timer", { repeat: true, duration: 9 })
    m.giro.observeField("fire", "girar")

    aplicarVisual()
    tique()
    m.menu.setFocus(true)
    t = chamar("ApiTask", "banner", { modo: "cache" }, "aoBannerCache")
end sub

sub retomar()
    ' voltou de outra tela: o controle parental trava de novo na Home
    m.global.parentalLiberado = false
    tique()
    m.giro.control = "start"
    m.menu.setFocus(true)
end sub

sub encerrar()
    m.relogio.control = "stop"
    m.giro.control = "stop"
end sub

sub tique()
    m.hora.text = horaAgora()
    lic = m.global.lic
    if lic = invalid or not isAA(lic) then lic = {}
    txt = licTextoCurto(lic, m.global.ehParceiro)
    if m.global.ehParceiro then
        txt = tx("Ativo parceiro")
        if sv(m.global.parceiroNome) <> "" then txt = txt + "  •  " + sv(m.global.parceiroNome)
    else
        txt = tx(txt)
    end if
    m.licTxt.text = txt
    avisos()
end sub

' Avisos de vencimento e campanha da VPS (uma faixa só: o aviso mais urgente primeiro).
sub avisos()
    textos = licAvisos(m.global.lic, m.global.ehParceiro, iv(m.global.info.exp_date))
    cor = uiDestaque()
    v = m.global.visual
    if v <> invalid and isAA(v) and sv(v.aviso_texto) <> "" then
        vale = true
        ate = sv(v.aviso_ate)
        if Len(ate) = 10 then
            hoje = CreateObject("roDateTime")
            h = hoje.ToISOString()
            if Left(h, 10) > ate then vale = false
        end if
        if vale then
            t = sv(v.aviso_texto)
            if sv(v.aviso_titulo) <> "" then t = sv(v.aviso_titulo) + " — " + t
            textos.Push(t)
            c = sv(v.aviso_cor)
            if Len(c) = 7 and Left(c, 1) = "#" then cor = "0x" + UCase(Mid(c, 2)) + "FF"
        end if
    end if
    if textos.Count() = 0 then
        m.faixa.visible = false
        m.faixaCor.visible = false
        m.faixaTxt.text = ""
        return
    end if
    m.faixaTxt.text = tx(textos[0])
    m.faixaCor.color = cor
    m.faixa.visible = true
    m.faixaCor.visible = true
end sub

sub aplicarVisual()
    avisos()
end sub

' ── Destaque ────────────────────────────────────────────────────────
sub aoBannerCache(ev as Object)
    chamarFim(ev)
    r = ev.getData()
    if r.ok = true then usarSlides(r.slides)
    chamar("ApiTask", "banner", { modo: "rede" }, "aoBannerRede")
end sub

sub aoBannerRede(ev as Object)
    chamarFim(ev)
    r = ev.getData()
    if r.ok = true and r.slides.Count() > 0 then usarSlides(r.slides)
end sub

sub usarSlides(lista as Object)
    m.slides = lista
    if m.pos >= lista.Count() then m.pos = 0
    mostrarSlide()
    m.giro.control = "start"
end sub

sub mostrarSlide()
    if m.slides.Count() = 0 then return
    s = m.slides[m.pos]
    m.capa.uri = sv(s.capa)
    m.etiqueta.text = tx(sv(s.etiqueta))
    m.nome.text = sv(s.nome)
    meta = ""
    if sv(s.nota) <> "" then meta = "★ " + sv(s.nota)
    if sv(s.ano) <> "" then
        if meta <> "" then meta = meta + "  •  "
        meta = meta + sv(s.ano)
    end if
    m.meta.text = meta
    pts = ""
    for i = 0 to m.slides.Count() - 1
        if i = m.pos then pts = pts + "● " else pts = pts + "○ "
    end for
    m.pontos.text = pts
end sub

sub girar()
    if m.slides.Count() < 2 then return
    if m.bt.hasFocus() or m.menu.hasFocus() then
        m.pos = (m.pos + 1) mod m.slides.Count()
        mostrarSlide()
    end if
end sub

sub aoDestaque(ev as Object)
    if m.slides.Count() = 0 then return
    s = m.slides[m.pos]
    uiAcao("abrir", { tela: "Detalhe", args: { tipo: sv(s.tipo), id: sv(s.id), nome: sv(s.nomeBruto), capa: sv(s.capa), ext: "", cat: "" } })
end sub

sub aoMenu(ev as Object)
    i = ev.getData()
    if i = 0 then
        uiAcao("abrir", { tela: "Live", args: {} })
    else if i = 1 then
        uiAcao("abrir", { tela: "Catalogo", args: { tipo: "filmes" } })
    else if i = 2 then
        uiAcao("abrir", { tela: "Catalogo", args: { tipo: "series" } })
    else if i = 3 then
        uiAcao("abrir", { tela: "Listas", args: {} })
    else
        uiAcao("abrir", { tela: "Ajustes", args: {} })
    end if
end sub

function onKeyEvent(tecla as String, pressionou as Boolean) as Boolean
    if not pressionou then return false
    if tecla = "right" and m.menu.hasFocus() and m.slides.Count() > 0 then
        m.bt.setFocus(true)
        return true
    else if tecla = "left" and m.bt.isInFocusChain() then
        m.menu.setFocus(true)
        return true
    else if (tecla = "up" or tecla = "down") and m.bt.isInFocusChain() then
        return true
    else if tecla = "options" then
        uiAcao("abrir", { tela: "Ajustes", args: {} })
        return true
    end if
    return false
end function
