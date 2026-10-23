' VLTV Play - Roku | Ativação igual à da LG: logo, título, código da TV em caixa, site, botões. Confere sozinho a cada 15 segundos.

sub iniciar()
    carregarI18n()
    lic = m.global.lic
    if lic = invalid or not isAA(lic) then lic = {}
    estado = sv(lic.estado)
    sem = (estado = "erro" or estado = "")
    bloq = (estado = "blocked")
    m.temOutra = (regGet("pendente") = "1" and not sem and not bloq)

    vkFundo(m.top)
    msg = sv(m.top.args.msg)
    if bloq then
        titulo = "Aparelho bloqueado"
        texto = "Este aparelho foi bloqueado. Fale com o suporte informando o código abaixo."
    else if sem then
        titulo = "Sem conexão com o servidor"
        texto = "Conecte a TV à internet e aperte OK para tentar de novo."
    else
        titulo = "Ative o seu VLTV Play"
        texto = "Para continuar assistindo, ative a licença desta TV."
        if msg <> "" then texto = msg
    end if

    ' altura total (centralizada como o flex da LG)
    linhas = 1
    if Len(tx(texto)) > 62 then linhas = 2
    total = 100 + 40 + 58 + 18 + 45 * linhas
    if not sem then total = total + 10 + 34 + 8 + 140 + 24
    if not sem and not bloq then total = total + 45
    total = total + 12 + 96
    if m.temOutra then total = total + 18 + 96
    y = 60 + Int((960 - total) / 2)
    if y < 60 then y = 60

    vkImg(m.top, 706, y + 8, 508, 58, "logo_84", "")
    y = y + 140
    vkTxt(m.top, 160, y, 1600, 58, tx(titulo), 48, true, cTexto(), "center")
    y = y + 76
    vkTxtM(m.top, 410, y, 1100, 45 * linhas, tx(texto), 32, false, cSuave(), 2, "center")
    y = y + 45 * linhas
    if not sem then
        y = y + 10
        vkTxt(m.top, 560, y, 800, 34, tx("Código desta TV"), 26, false, cSuave(), "center")
        y = y + 42
        cod = sv(lic.codigo)
        if cod = "" then cod = "--------"
        esp = ""
        for i = 1 to Len(cod)
            if i > 1 then esp = esp + " "
            esp = esp + Mid(cod, i, 1)
        end for
        medidor = uiNo(m.top, "Label", { text: esp, font: vkFonte(96, true), visible: false })
        larg = Int(medidor.boundingRect().width)
        if larg < 200 then larg = Len(esp) * 56
        cw = larg + 88
        caixa = vkCaixa(m.top, Int((1920 - cw) / 2), y, cw, 140, 18, 2, 6)
        vkPintar(caixa, cBorda(), cPainel2(), false)
        vkTxt(caixa.grupo, 0, 0, cw, 140, esp, 96, true, cTexto(), "center")
        y = y + 140 + 24
        if not bloq then
            site = sv(lic.pagar_url)
            if site = "" then site = "vltvplay.tech/ativar"
            a = tx("No celular ou computador, acesse ")
            b = site
            c = tx(" e informe o código.")
            la = uiNo(m.top, "Label", { text: a, font: vkFonte(32, false), visible: false })
            lb = uiNo(m.top, "Label", { text: b, font: vkFonte(32, true), visible: false })
            lc = uiNo(m.top, "Label", { text: c, font: vkFonte(32, false), visible: false })
            wa = Int(la.boundingRect().width)
            wb = Int(lb.boundingRect().width)
            wc = Int(lc.boundingRect().width)
            x0 = Int((1920 - (wa + wb + wc)) / 2)
            vkTxt(m.top, x0, y, wa + 4, 45, a, 32, false, cSuave(), "left")
            vkTxt(m.top, x0 + wa, y, wb + 4, 45, b, 32, true, cBranco(), "left")
            vkRet(m.top, x0 + wa, y + 40, wb, 5, cDest())
            vkTxt(m.top, x0 + wa + wb, y, wc + 4, 45, c, 32, false, cSuave(), "left")
            y = y + 45
        end if
    end if
    y = y + 12
    m.btn = []
    if sem then
        rot1 = "Tentar novamente"
    else
        rot1 = "Já ativei — verificar"
    end if
    m.btn.Push(vkBotao(m.top, 510, y, 900, 96, tx(rot1), 38))
    if m.temOutra then
        y = y + 96 + 18
        m.btn.Push(vkBotao(m.top, 510, y, 900, 96, tx("Usar outra lista"), 38))
    end if
    m.sel = 0
    m.ocupado = false
    pintar()
    m.top.setFocus(true)
    m.tempo = uiNo(m.top, "Timer", { repeat: true, duration: 15 })
    m.tempo.observeField("fire", "verificar")
    m.tempo.control = "start"
end sub

sub pintar()
    for i = 0 to m.btn.Count() - 1
        b = m.btn[i]
        if i = m.sel then
            vkPintar(b.caixa, cBranco(), cDest(), true)
            b.caixa.glow.opacity = 0.5
        else
            vkPintar(b.caixa, "", cDest(), false)
        end if
    end for
end sub

sub retomar()
    m.top.setFocus(true)
end sub

sub focar()
    m.top.setFocus(true)
end sub

sub encerrar()
    m.tempo.control = "stop"
end sub

function onKeyEvent(tecla as String, pressionou as Boolean) as Boolean
    if not pressionou then return false
    if tecla = "up" or tecla = "down" then
        if m.btn.Count() > 1 then
            if m.sel = 0 then m.sel = 1 else m.sel = 0
            pintar()
        end if
        return true
    else if tecla = "OK" then
        if m.sel = 1 then
            m.tempo.control = "stop"
            uiAcao("abrir", { tela: "Listas", args: { msg: "Escolha uma lista para entrar." } })
        else
            verificar()
        end if
        return true
    end if
    return false
end function

sub verificar()
    if m.ocupado = true then return
    m.ocupado = true
    chamar("AuthTask", "licenca", {}, "aoLicenca")
end sub

sub aoLicenca(ev as Object)
    chamarFim(ev)
    m.ocupado = false
    r = ev.getData()
    estado = sv(r.estado)
    if estado = "active" or estado = "trial" then
        m.global.lic = r
        m.tempo.control = "stop"
        if regGet("pendente") = "1" then
            ' Tentou abrir uma lista nova: ativou, agora é ELA que abre (os dados já estão no formulário).
            regSet("pendente", "")
            uiAcao("login", { msg: "Licença ativa! Aperte Entrar para abrir a lista." })
        else
            uiAcao("carregando", { ligado: true, texto: "Entrando..." })
            uiAcao("trocarlista", invalid)
        end if
    else if estado = "blocked" or estado = "erro" then
        m.global.lic = r
    end if
end sub
