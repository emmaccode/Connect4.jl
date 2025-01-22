module Connect4
using Toolips
using Toolips.Components
using ToolipsSession

# extensions
logger = Toolips.Logger()
SESSION = ToolipsSession.Session(["/", "/game"])
# we will eventually fill `GAMES` with the currently active games.
#   we will add them using `push!`, pushing a `Pair{String, Pair{String, Int64}}` ("username" => "ip" => n_players)
mutable struct GameData
    ip::String
    players::UInt8
    fills::Matrix{Int8}
    peer::String
end

GAMES = Dict{String, GameData}()


function games_list(c::Toolips.AbstractConnection)
    # styles:
    header_label = style("div.headerlabel", "padding" => 10px, "font-size" => 16pt, "color" => "white", "font-weight" => "bold", 
    "width" => 50percent)
    obs_label = style("div.obslabel", "padding" => 10px, "font-size" => 16pt, "color" => "#333333", "width" => 50percent, 
    "pointer-events" => "none")
    active_server = style("div.active-server", "display" => "inline-flex", "width" => 100percent, "transition" => 600ms, 
    "cursor" => "pointer")
    active_server:"hover":["transform" => "scale(1.06)", "border-left" => "3px solid green"]
    write!(c, header_label, obs_label, active_server)
    # i set the class of our new sections to our style names, provide them as children to `header_box`
    section1, section2 = div("-", text = "name", class = "headerlabel"), div("-", text = "players", class = "headerlabel")
    header_box = div("list-header", children = [section1, section2])
    # style header box
    style!(header_box, "background-color" => "darkblue", "display" => "inline-flex", "width" => 100percent)
    # build list_items -- the selectable components that represent the current games.
    list_items = [begin
        name = game[1]
        gameinfo = game[2]
        game_ip = gameinfo.ip
        n_players = gameinfo.players
        section1, section2 = div("-", text = name, class = "obslabel"), div("-", text = "$(n_players)/2", class = "obslabel")
        user_box = div(name, children = [section1, section2], class = "active-server")
        on(c, user_box, "dblclick") do cm::ComponentModifier
            GAMES[name].peer = get_ip(c)
            redirect!(cm, "/game")
        end
        if n_players > 1
            style!(user_box, "border-left" => "5px solid red")
        else
            style!(user_box, "background-color" => "white")
        end
        user_box
    end for game in GAMES]
    # new game button:
    new_game = div("newgame", text = "create new game", align = "center")
    style!(new_game, "width" => 98percent, "padding" => 1percent, "font-weight" => "bold", "background-color" => "darkgreen", 
    "color" => "white", "font-size" => 15pt, "cursor" => "pointer")
    on(c, new_game, "click") do cm::ComponentModifier
        if "newgdialog" in cm
            return
        end
        inputbox = Components.textdiv("name-input")
        style!(inputbox, "background-color" => "white", "color" => "black", "border" => "2px solid #333333")
        confirm_butt, cancel_butt = button("confirm", text = "confirm"), button("cancel", text = "cancel")
        on(c, confirm_butt, "click") do cm::ComponentModifier
            game_name = cm["name-input"]["text"]
            fills = hcat([[0 for y in 1:6] for x in 1:7] ...)
            new_game_data = GameData(get_ip(c), UInt8(1), fills, "")
            push!(GAMES, game_name => new_game_data)
            redirect!(cm, "/game")
        end
        on(c, cancel_butt, "click") do cm::ComponentModifier

        end
        new_game_dialog = div("newgdialog", children = [inputbox, confirm_butt, cancel_butt])
        style!(new_game_dialog, "position" => "absolute", "left" => 35percent, "top" => 45percent, 
        "width" => 30percent, "padding" => 10px, "z-index" => 5,
        "display" => "inline-block", "opacity" => 0percent, "transform" => "translateY(10%)", "background-color" => "darkred",
        "transition" => 650ms)
        name_header = h3(text = "name your game")
        append!(cm, "mainbody", new_game_dialog)
        on(cm, 300) do cm2::ClientModifier
            style!(cm2, "newgdialog", "opacity" => 100percent, "transform" => translateY(0percent))
            focus!(cm2, "name-input")
        end
    end
    # assemble our header_box (and list items) (and now new game button) into a dialog:
    dialog_window = div("main-dialog", children = [header_box, list_items ..., new_game])
    style!(dialog_window, "position" => "absolute", 
    "width" => 30percent, "top" => 16percent, "left" => 35percent, 
    "border-radius" => 3px, "border" => "2px solid #333333")
    # compose into body and return:
    mainbody = body("mainbody", children = [dialog_window])
end

# our main route, simply writes the returned dialog from `games_list`.
main = route("/") do c::Toolips.AbstractConnection
    write!(c, games_list(c))
end

get_game(ip::String) = begin
    f = findfirst(gameinfo -> gameinfo[2].ip == ip, GAMES)
    if ~(isnothing(f))
        return(GAMES[f], true)
    end
    f = findfirst(gameinfo -> gameinfo[2].peer == ip, GAMES)
    if ~(isnothing(f))
        return(GAMES[f], false)
    end
    return(nothing, false)
end

game = route("/game") do c::Toolips.AbstractConnection
    ip::String = get_ip(c)
    gameinfo, is_host::Bool = get_game(ip)
    if isnothing(gameinfo)
        scr = on(100) do cl::ClientModifier
            redirect!(cl, "/")
        end
        write!(c, scr)
        return
    end
    build_game(c, gameinfo, is_host)
end

function build_game(c, gameinfo, is_host)
    
    [begin

    end for col in eachcol(gameinfo.fills)]
end


export main, default_404, logger, SESSION, game
end # - module Connect4 <3