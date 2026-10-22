' VLTV Play - Roku | Login: abas Usuário / Xtream / Lista M3U. No campo do servidor, um código de parceiro também vale.

sub iniciar()
    carregarI18n()
    m.modo = ultimaAba()
    if m.modo = "parceiro" then m.modo = "xtream"
    m.vals = regJson("form")
    if m.vals = invalid or not isAA(m.vals) then m.vals = {}
    m.ocupado = false

    uiRet(m.top, 0, 0, 1920, 1080, uiFundo())
    uiFoto(m.top, 80, 60, 120, 120, "pkg:/images/logo.png", false)
    uiLinha(m.top, 220, 80, 900, "VLTV Play", "font:LargeBoldSystemFont", uiTexto())
    uiLinha(m.top, 220, 135, 900, "Entre para assistir", "font:SmallSystemFont", uiSuave())

    m.abas = uiBotoes(m.top, 620, 220, ["Usuário", "Xtream", "Lista M3U"], true)
    m.abas.minWidth = 220
    m.abas.observeField("buttonFocused", "aoAba")
    m.abas.observeField("buttonSelected", "aoAbaOk")

    m.campos = uiLista(m.top, 620, 330, 680, 5, 76)
    m.campos.observeField("itemSelected", "aoCampo")

    m.status = uiTxt(m.top, 620, 760, 900, 120, "", "font:MediumSystemFont", uiErro())
    uiTxt(m.top, 80, 940, 1760, 40, "Use as setas e OK. Para digitar, aperte OK no campo.", "font:SmallSystemFont", uiSuave())
    m.dica = uiTxt(m.top, 620, 280, 900, 40, "", "font:SmallSystemFont", uiSuave())

    msg = sv(m.top.args.msg)
    if msg <> "" then m.status.text = tx(msg)

    indiceAba = 0
    if m.modo = "xtream" then indiceAba = 1
    if m.modo = "m3u" then indiceAba = 2
    m.abas.focusButton = indiceAba
    desenhar()
    m.campos.setFocus(true)
end sub

sub retomar()
    if not m.ocupado then m.campos.setFocus(true)
end sub

sub encerrar()
end sub

' Linhas da lista conforme a aba.
function linhasDaAba() as Object
    if m.modo = "m3u" then
        return [{ k: "m3u", rot: "Endereço da lista", senha: false }, { k: "entrar", rot: "ENTRAR" }]
    else if m.modo = "xtream" then
        return [{ k: "servidor", rot: "Servidor ou código", senha: false }, { k: "user", rot: "Usuário", senha: false }, { k: "pass", rot: "Senha", senha: true }, { k: "entrar", rot: "ENTRAR" }]
    end if
    return [{ k: "user", rot: "Usuário", senha: false }, { k: "pass", rot: "Senha", senha: true }, { k: "entrar", rot: "ENTRAR" }]
end function

function chaveVal(k as String) as String
    if k = "user" or k = "pass" then return m.modo + "_" + k
    return k
end function

sub desenhar()
    m.linhas = linhasDaAba()
    textos = []
    for each l in m.linhas
        if l.k = "entrar" then
            textos.Push(tx(l.rot))
        else
            v = sv(m.vals[chaveVal(l.k)])
            if l.senha then
                mascara = ""
                for i = 1 to Len(v)
                    mascara = mascara + "*"
                next
                v = mascara
            end if
            if v = "" then v = "..."
            textos.Push(tx(l.rot) + ":  " + v)
        end if
    end for
    m.campos.content = uiItensLista(textos)
    m.campos.numRows = textos.Count()
    if m.modo = "usuario" then
        m.dica.text = tx("Use o usuário e a senha do VLTV Play.")
    else if m.modo = "xtream" then
        m.dica.text = tx("Endereço do servidor (http://...) ou o código do parceiro.")
    else
        m.dica.text = tx("Endereço da lista M3U.")
    end if
end sub

sub aoAba(ev as Object)
    i = ev.getData()
    modos = ["usuario", "xtream", "m3u"]
    if i >= 0 and i < 3 and modos[i] <> m.modo then
        m.modo = modos[i]
        m.status.text = ""
        desenhar()
    end if
end sub

sub aoAbaOk(ev as Object)
    m.campos.setFocus(true)
end sub

sub aoCampo(ev as Object)
    if m.ocupado then return
    i = ev.getData()
    l = m.linhas[i]
    if l.k = "entrar" then
        entrar()
        return
    end if
    m.campoAtual = l
    dica = "Digite e confirme."
    uiTeclado(l.rot, dica, sv(m.vals[chaveVal(l.k)]), l.senha, tecladoOk)
end sub

sub tecladoOk(texto as String)
    m.vals[chaveVal(m.campoAtual.k)] = texto.Trim()
    desenhar()
    m.campos.setFocus(true)
end sub

function onKeyEvent(tecla as String, pressionou as Boolean) as Boolean
    if not pressionou then return false
    if tecla = "up" and m.campos.isInFocusChain() and m.campos.itemFocused = 0 then
        m.abas.setFocus(true)
        return true
    else if tecla = "down" and m.abas.isInFocusChain() then
        m.campos.setFocus(true)
        return true
    end if
    return false
end function

' ── Entrar ──────────────────────────────────────────────────────────
sub entrar()
    ctx = { modo: m.modo }
    m.status.color = uiErro()
    if m.modo = "m3u" then
        u = sv(m.vals.m3u)
        if u = "" then
            m.status.text = tx("Digite o endereço da lista.")
            return
        end if
        if not startsWith(LCase(u), "http") then u = "http://" + u
        ctx.m3u = u
    else
        user = sv(m.vals[m.modo + "_user"])
        pass = sv(m.vals[m.modo + "_pass"])
        if user = "" or pass = "" then
            m.status.text = tx("Digite o usuário e a senha.")
            return
        end if
        ctx.user = user
        ctx.pass = pass
        if m.modo = "xtream" then
            srv = sv(m.vals.servidor)
            if srv = "" then
                m.status.text = tx("Digite o servidor ou o código do parceiro.")
                return
            end if
            ' Sem ponto, dois-pontos ou barra: é um código de parceiro.
            if Instr(1, srv, ".") = 0 and Instr(1, srv, ":") = 0 and Instr(1, srv, "/") = 0 then
                ctx.modo = "parceiro"
                ctx.codigo = srv
                ctx.dnsPreferido = ""
            else
                ctx.servidor = srv
            end if
        end if
    end if
    m.ctx = ctx
    regJsonSet("form", m.vals)
    regSet("aba", m.modo)
    m.ocupado = true
    m.status.color = uiSuave()
    m.status.text = tx("Entrando...")
    uiAcao("carregando", { ligado: true, texto: "Entrando..." })
    autenticarPar(ctx, aoResultado)
end sub

sub aoResultado(r as Object)
    m.ocupado = false
    estado = sv(r.estado)
    m.status.color = uiErro()
    if estado = "ok" then
        guardarSessao(r)
        return
    end if
    uiAcao("carregando", { ligado: false })
    if estado = "sem_licenca" then
        if r.lic <> invalid then m.global.lic = r.lic
        regSet("pendente", "1")   ' depois de ativar, volta aqui para abrir ESTA lista
        uiAcao("ativacao", invalid)
        return
    end if
    m.status.text = tx(mensagemDe(estado, r))
    m.campos.setFocus(true)
end sub

function mensagemDe(estado as String, r as Object) as String
    if estado = "expirado" then
        if r.teste = true then return "O teste dessa lista terminou."
        return "Essa lista está vencida. Fale com o seu provedor."
    else if estado = "invalido" then
        return "Usuário ou senha incorretos."
    else if estado = "codigo_invalido" then
        return "Código de parceiro não encontrado."
    else if estado = "suspenso" then
        return "Esse código de parceiro está suspenso."
    else if estado = "limite" then
        return "Muitas tentativas. Espere um pouco e tente de novo."
    else if estado = "m3u_grande" then
        return "A lista M3U é grande demais para a Roku."
    else if estado = "m3u_vazia" then
        return "A lista M3U não tem canais, filmes ou séries."
    end if
    return "Não foi possível conectar. Confira o endereço e a internet."
end function

sub guardarSessao(r as Object)
    c = m.ctx
    d = { modo: c.modo }
    if c.modo = "m3u" then
        d.m3u = c.m3u
    else
        d.user = c.user
        d.pass = c.pass
        if c.modo = "parceiro" then
            d.codigo = UCase(c.codigo)
            d.dns = sv(r.base)
            d.parceiro = sv(r.nome)
        else if c.modo = "xtream" then
            d.dns = sv(r.base)
        else
            d.painel = sv(r.painel)
        end if
    end if
    regSet("pendente", "")
    sessaoSalvar(d)
    listaRegistrar(d)
    ' Entra na hora. O aviso à VPS (código de parceiro = TV ativa; outra lista = sem parceiro) vai por trás.
    codigo = ""
    if c.modo = "parceiro" then codigo = UCase(c.codigo)
    if r.lic <> invalid then m.global.lic = r.lic
    uiAcao("carregando", { ligado: false })
    uiAcao("entrou", { info: r.info, base: sv(r.base), nome: sv(r.nome), informar: codigo })
end sub

sub focar()
    if m.ocupado = true then return
    m.campos.setFocus(true)
end sub
