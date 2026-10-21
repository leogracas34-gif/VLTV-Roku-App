' VLTV Play - Roku | Minhas listas: trocar, remover ou adicionar.

sub iniciar()
    carregarI18n()
    uiRet(m.top, 0, 0, 1920, 1080, uiFundo())
    uiLinha(m.top, 80, 50, 900, "Minhas listas", "font:LargeBoldSystemFont", uiTexto())
    m.lista = uiLista(m.top, 80, 160, 1500, 7, 110)
    m.lista.observeField("itemSelected", "aoItem")
    m.dica = uiNo(m.top, "Label", { translation: [80, 960], width: 1700, font: "font:SmallSystemFont", color: uiSuave(), text: tx("OK: escolher a lista") })
    desenhar()
    m.lista.setFocus(true)
end sub

sub retomar()
    desenhar()
    m.lista.setFocus(true)
end sub

sub encerrar()
end sub

sub desenhar()
    m.listas = listasTodas()
    ativa = listaAtivaId()
    textos = []
    for each e in m.listas
        r = rotuloLista(e)
        marca = ""
        if e.id = ativa then marca = "✔ "
        textos.Push(marca + sv(r.titulo) + "   (" + sv(r.tipo) + ")")
    end for
    textos.Push(tx("+ Adicionar nova lista"))
    m.lista.content = uiItensLista(textos)
end sub

sub aoItem(ev as Object)
    i = ev.getData()
    if i >= m.listas.Count() then
        uiAcao("abrir", { tela: "Login", args: {} })
        return
    end if
    m.escolhida = m.listas[i]
    d = CreateObject("roSGNode", "Dialog")
    d.title = tx(sv(rotuloLista(m.escolhida).titulo))
    d.buttons = [tx("Usar esta lista"), tx("Remover"), tx("Cancelar")]
    d.observeFieldScoped("buttonSelected", "aoEscolha")
    m.top.getScene().dialog = d
end sub

sub aoEscolha(ev as Object)
    d = ev.getRoSGNode()
    i = ev.getData()
    d.close = true
    if i = 0 then
        e = m.escolhida
        sessaoSalvar({ modo: sv(e.modo), dns: sv(e.dns), user: sv(e.user), pass: sv(e.pass), codigo: sv(e.codigo), m3u: sv(e.m3u), parceiro: sv(e.parceiro) })
        regSet("lista_ativa", sv(e.id))
        uiAcao("trocarlista", invalid)
    else if i = 1 then
        listaRemover(sv(m.escolhida.id))
        if listaAtivaId() = "" then
            sessaoLimpar()
            uiAcao("sair", invalid)
        else
            desenhar()
        end if
    end if
end sub
