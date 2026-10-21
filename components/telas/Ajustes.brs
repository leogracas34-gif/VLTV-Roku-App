' VLTV Play - Roku | Configurações: conta, idioma, controle parental, limpar cache, sair e sobre.

sub iniciar()
    carregarI18n()
    uiRet(m.top, 0, 0, 1920, 1080, uiFundo())
    uiLinha(m.top, 80, 50, 900, "Configurações", "font:LargeBoldSystemFont", uiTexto())
    m.lista = uiLista(m.top, 80, 160, 760, 7, 100)
    m.detalhe = uiNo(m.top, "Label", { translation: [900, 170], width: 920, height: 700, wrap: true, font: "font:MediumSystemFont", color: uiSuave() })
    m.lista.observeField("itemSelected", "aoItem")
    m.lista.observeField("itemFocused", "aoFoco")
    desenhar()
    m.lista.setFocus(true)
    aoFoco(invalid)
end sub

sub retomar()
    m.lista.setFocus(true)
end sub

sub encerrar()
end sub

sub desenhar()
    idioma = "Português (Brasil)"
    if idiomaEn() then idioma = "English"
    m.lista.content = uiItensLista(["Informações da conta", tx("Idioma") + ": " + idioma, "Controle parental", "Limpar cache", "Trocar de conta / Sair", "Sobre"])
end sub

sub aoFoco(ev as Object)
    i = m.lista.itemFocused
    txt = ""
    if i = 0 then txt = "Usuário, vencimento do plano e licença deste aparelho."
    if i = 1 then txt = "Troca o idioma do aplicativo. Em inglês, títulos e sinopses vêm do TMDB."
    if i = 2 then txt = "Protege conteúdo +18 com senha de 4 dígitos (padrão 0000). Troque a senha assim que ativar."
    if i = 3 then txt = "Apaga imagens e listas guardadas na TV. Favoritos e o ponto onde você parou são mantidos. A pesquisa de Filmes e Séries será baixada de novo."
    if i = 4 then txt = "Sai desta conta e volta para a tela de login."
    if i = 5 then txt = "Versão do aplicativo e contato do suporte."
    m.detalhe.text = tx(txt)
end sub

sub aoItem(ev as Object)
    i = ev.getData()
    if i = 0 then
        mostrarConta()
    else if i = 1 then
        if idiomaEn() then
            regSet("idioma", "pt-BR")
            m.global.idioma = "pt-BR"
        else
            regSet("idioma", "en")
            m.global.idioma = "en"
        end if
        uiAcao("idioma", invalid)
    else if i = 2 then
        uiPin("Senha dos pais", pinParental)
    else if i = 3 then
        uiConfirmar("Limpar cache", "Apagar imagens e listas guardadas?", "Limpar", "Cancelar", limpar)
    else if i = 4 then
        uiConfirmar("Sair da conta", "Deseja sair desta conta?", "Sair", "Cancelar", sairConta)
    else
        uiAviso("Sobre", "VLTV Play " + sv(cfg().versao) + Chr(10) + tx("Suporte") + ": " + sv(cfg().suporte))
    end if
end sub

sub limpar()
    limparCacheTudo()
    uiAviso("Pronto", "Cache apagado.")
end sub

sub sairConta()
    uiAcao("sair", invalid)
end sub

sub mostrarConta()
    s = sessaoLer()
    info = m.global.info
    linhas = []
    if s <> invalid then
        if s.modo = "m3u" then
            linhas.Push(tx("Lista M3U") + ": " + hostDe(sv(s.m3u)))
        else
            linhas.Push(tx("Usuário") + ": " + sv(s.user))
            if s.modo = "parceiro" then linhas.Push(tx("Código de parceiro") + ": " + sv(s.codigo))
        end if
    end if
    if info <> invalid and isAA(info) then
        exp = nv(info.exp_date)
        if exp > 0 then
            linhas.Push(tx("Plano vence em") + ": " + dataBr(exp))
        else if sv(info.exp_date) = "" and s <> invalid and s.modo <> "m3u" then
            linhas.Push(tx("Plano sem vencimento"))
        end if
        if sv(info.max_connections) <> "" then linhas.Push(tx("Telas simultâneas") + ": " + sv(info.max_connections))
    end if
    textoLic = licTextoCurto(m.global.lic, m.global.ehParceiro)
    if textoLic = "" then textoLic = "Não verificada (sem resposta do servidor)"
    linhas.Push(tx("Licença do aplicativo") + ": " + tx(textoLic))
    linhas.Push(tx("Dispositivo") + ": " + licIdentidade().id)
    uiAviso("Informações da conta", linhas.Join(Chr(10)))
end sub

' ── Controle parental ───────────────────────────────────────────────
sub pinParental(pin as String)
    if not pinConfere(pin) then
        uiAviso("Senha incorreta", "A senha não confere.")
        return
    end if
    menuParental()
end sub

sub menuParental()
    e = parentalLer()
    textos = []
    m.parAcoes = []
    if e.ativo then textos.Push(tx("Desativar proteção +18")) else textos.Push(tx("Ativar proteção +18"))
    m.parAcoes.Push("ativo")
    if e.modo = "ocultar" then textos.Push(tx("Modo: ocultar conteúdo +18")) else textos.Push(tx("Modo: pedir senha"))
    m.parAcoes.Push("modo")
    textos.Push(tx("Alterar senha"))
    m.parAcoes.Push("senha")
    textos.Push(tx("Pergunta secreta"))
    m.parAcoes.Push("pergunta")
    textos.Push(tx("Fechar"))
    m.parAcoes.Push("fechar")
    d = CreateObject("roSGNode", "Dialog")
    d.title = tx("Controle parental")
    d.buttons = textos
    d.observeFieldScoped("buttonSelected", "aoMenuParental")
    m.top.getScene().dialog = d
end sub

sub aoMenuParental(ev as Object)
    d = ev.getRoSGNode()
    acao = m.parAcoes[ev.getData()]
    d.close = true
    e = parentalLer()
    if acao = "ativo" then
        parentalDefinirAtivo(not e.ativo)
        m.global.parentalLiberado = false
        menuParental()
    else if acao = "modo" then
        if e.modo = "ocultar" then parentalDefinirModo("senha") else parentalDefinirModo("ocultar")
        menuParental()
    else if acao = "senha" then
        uiPin("Nova senha (4 dígitos)", novaSenha)
    else if acao = "pergunta" then
        escolherPergunta()
    end if
end sub

sub novaSenha(pin as String)
    if Len(pin) <> 4 then
        uiAviso("Senha", "A senha precisa ter 4 dígitos.")
        return
    end if
    parentalDefinirPin(pin)
    uiAviso("Pronto", "Senha alterada.")
end sub

sub escolherPergunta()
    d = CreateObject("roSGNode", "Dialog")
    d.title = tx("Pergunta secreta")
    d.message = [tx("Serve para recuperar a senha se você esquecer.")]
    d.buttons = perguntasSecretas()
    d.observeFieldScoped("buttonSelected", "aoPergunta")
    m.top.getScene().dialog = d
end sub

sub aoPergunta(ev as Object)
    d = ev.getRoSGNode()
    m.perguntaIdx = ev.getData()
    d.close = true
    uiTeclado("Sua resposta", perguntasSecretas()[m.perguntaIdx], "", false, respostaDigitada)
end sub

sub respostaDigitada(texto as String)
    if Len(texto.Trim()) < 2 then
        uiAviso("Resposta", "Digite uma resposta.")
        return
    end if
    parentalDefinirPergunta(m.perguntaIdx, texto)
    uiAviso("Pronto", "Pergunta secreta salva.")
end sub
