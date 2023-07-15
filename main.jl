using ChineseCheckers

player_1_model = load_model("models/player_1/mark_1.jld2")
player_2_model = load_model("models/player_2/mark_1.jld2")

train_models(
    player_1_model,
    player_2_model,
    epoch=1000,
    show_every=100
)

