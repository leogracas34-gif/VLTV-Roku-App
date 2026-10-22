' VLTV Play - Roku | Ativação: código da TV + site. Confere sozinho a cada 15 segundos.

sub iniciar()
    carregarI18n()
    lic = m.global.lic
    if lic = invalid or not isAA(lic) then lic = {}
    uiRet(m.top, 0, 0, 1920, 1080, uiFundo())
    uiFoto(m.top, 80, 60, 120, 120, "pkg:/images/logo.png", false)
    uiLinha(m.top, 220, 90, 1200, "Ative o seu VLTV Play", "font:LargeBoldSystemFont", uiTexto())
    estado = sv(lic.estado)
    texto = "O teste grátis desta TV terminou."
    if estado = "blocked" then texto = "Esta TV está bloqueada. Fale com o suporte."
    if estado = "active" or estado = "trial" then texto = "Licença ativa. Entrando..."
    if estado = "erro" or estado = "" then texto = "Não foi possível verificar a licença. Confira a internet."
    uiTxt(m.top, 220, 170, 1400, 60, texto, "font:MediumSystemFont", uiSuave())
    uiTxt(m.top, 220, 300, 1400, 50, "Código desta TV", "font:MediumSystemFont", uiSuave())
    cod = sv(lic.codigo)
    if cod = "" then cod = "-"
    uiLinha(m.top, 220, 350, 1400, cod, "font:LargeBoldSystemFont", uiDestaque())
    site = sv(lic.pagar_url)
    if site = "" then site = "vltvplay.tech/ativar"
    uiTxt(m.top, 220, 470, 1400, 50, "Acesse no celular ou computador:", "font:MediumSystemFont", uiSuave())
    uiLinha(m.top, 220, 520, 1400, site, "font:LargeSystemFont", uiTexto())
    m.status = uiTxt(m.top, 220, 640, 1400, 70, sv(m.top.args.msg), "font:SmallSystemFont", uiSuave())
    m.bt = uiBotoes(m.top, 220, 720, ["Já ativei, verificar", "Entrar com código de parceiro"], false)
    m.bt.observeField("buttonSelected", "aoBotao")
    m.bt.setFocus(true)
    m.tempo = uiNo(m.top, "Timer", { repeat: true, duration: 15 })
    m.tempo.observeField("fire", "verificar")
    m.tempo.control = "start"
end sub

sub retomar()
    m.bt.setFocus(true)
end sub

sub encerrar()
    m.tempo.control = "stop"
end sub

sub aoBotao(ev as Object)
    if ev.getData() = 0 then
        verificar()
    else
        uiAcao("login", { msg: "Digite o código de parceiro no campo Servidor (aba Xtream)." })
    end if
end sub

sub verificar()
    m.status.text = tx("Verificando...")
    chamar("AuthTask", "licenca", {}, "aoLicenca")
end sub

sub aoLicenca(ev as Object)
    chamarFim(ev)
    r = ev.getData()
    estado = sv(r.estado)
    if estado = "active" or estado = "trial" then
        m.global.lic = r
        m.tempo.control = "stop"
        if regGet("pendente") = "1" then
            ' A pessoa tentou abrir uma lista nova: ativou, agora é ELA que abre (os dados já estão no formulário).
            regSet("pendente", "")
            uiAcao("login", { msg: "Licença ativa! Toque em ENTRAR para abrir a lista." })
        else
            uiAcao("carregando", { ligado: true, texto: "Entrando..." })
            uiAcao("trocarlista", invalid)
        end if
    else
        m.status.text = tx("Ainda não ativada.")
    end if
end sub

function onKeyEvent(tecla as String, pressionou as Boolean) as Boolean
    return false
end function

sub focar()
    m.bt.setFocus(true)
end sub
