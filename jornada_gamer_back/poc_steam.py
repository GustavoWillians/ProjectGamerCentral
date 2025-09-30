import requests
import time
import json

# --- CONFIGURAÇÃO ---
# Cole sua chave da API da Steam aqui
API_KEY = "48C424D69881697ED5756D576A2CD69C" 
# Coloque seu ID Steam64 aqui. Se não souber, use um site como o "SteamID.io" para encontrar.
STEAM_ID = "76561198219730140" 
# --- FIM DA CONFIGURAÇÃO ---

def get_owned_games(api_key, steam_id):
    """Busca a lista de jogos de um usuário na API da Steam."""
    url = f"http://api.steampowered.com/IPlayerService/GetOwnedGames/v0001/?key={api_key}&steamid={steam_id}&format=json"
    try:
        response = requests.get(url)
        response.raise_for_status()  # Lança um erro se a requisição falhar
        return response.json()['response']['games']
    except requests.exceptions.RequestException as e:
        print(f"Erro ao buscar a lista de jogos: {e}")
        return None

def get_game_details(app_id):
    """Busca os detalhes (gêneros) de um jogo específico."""
    # A API de detalhes dos jogos pode ser instável, por isso usamos um endpoint alternativo
    url = f"https://store.steampowered.com/api/appdetails?appids={app_id}"
    try:
        response = requests.get(url)
        response.raise_for_status()
        data = response.json()
        
        # A resposta da API é um dicionário com o app_id como chave
        if str(app_id) in data and data[str(app_id)]['success']:
            game_data = data[str(app_id)]['data']
            if 'genres' in game_data:
                return [genre['description'] for genre in game_data['genres']]
        return []
    except (requests.exceptions.RequestException, KeyError, json.JSONDecodeError) as e:
        # print(f"Não foi possível obter detalhes para o appid {app_id}: {e}")
        return []

def calculate_archetype(games):
    """Calcula o arquétipo do jogador com base nos gêneros dos jogos."""
    genre_playtime = {}
    
    # Filtra jogos com mais de 60 minutos (1 hora) de jogo
    significant_games = [game for game in games if game.get('playtime_forever', 0) > 60]
    
    print(f"Analisando {len(significant_games)} jogos significativos...")
    
    for i, game in enumerate(significant_games):
        app_id = game['appid']
        playtime = game.get('playtime_forever', 0)
        
        # Obtém os gêneros do jogo
        genres = get_game_details(app_id)
        
        if genres:
            print(f"[{i+1}/{len(significant_games)}] Jogo: {app_id}, Gêneros: {', '.join(genres)}")
            for genre in genres:
                genre_playtime[genre] = genre_playtime.get(genre, 0) + playtime
        
        # Pausa para não sobrecarregar a API da Steam (importante!)
        time.sleep(1.5)

    if not genre_playtime:
        return {"erro": "Nenhum dado de gênero encontrado para os jogos analisados."}

    # Ordena os gêneros pelo tempo de jogo
    sorted_genres = sorted(genre_playtime.items(), key=lambda item: item[1], reverse=True)
    
    top_genre = sorted_genres[0][0]
    
    # Lógica de Arquétipo (simplificada para a PoC)
    archetype = "Jogador Versátil" # Padrão
    if top_genre in ["RPG", "Adventure"]:
        archetype = "Explorador de Mundos"
    elif top_genre in ["Strategy", "Simulation"]:
        archetype = "Mestre Estrategista"
    elif top_genre in ["Action", "Free to Play", "Massively Multiplayer"]:
        archetype = "Competidor Nato"
    elif top_genre in ["Indie", "Casual"]:
        archetype = "Aventureiro Indie"

    return {
        "usuario_id": STEAM_ID,
        "arquétipo_sugerido": archetype,
        "genero_principal": top_genre,
        "horas_no_genero_principal": round(sorted_genres[0][1] / 60, 1),
        "top_3_generos": {g: round(p / 60, 1) for g, p in sorted_genres[:3]}
    }

if __name__ == "__main__":
    owned_games = get_owned_games(API_KEY, STEAM_ID)
    if owned_games:
        final_archetype = calculate_archetype(owned_games)
        print("\n--- RESULTADO DA ANÁLISE ---")
        print(json.dumps(final_archetype, indent=2, ensure_ascii=False))