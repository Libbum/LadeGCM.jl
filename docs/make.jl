using Documenter, LadeGCM

makedocs()

deploydocs(
    deps   = Deps.pip("pygments", "mkdocs", "python-markdown-math"),
    repo   = "github.com/Libbum/LadeGCM.jl.git",
    julia  = "0.6"
)
