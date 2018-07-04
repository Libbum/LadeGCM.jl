using Documenter, CESEarth

makedocs()

deploydocs(
    deps   = Deps.pip("mkdocs", "python-markdown-math"),
    repo   = "github.com/Libbum/CES.Earth.git",
    julia  = "0.6"
)
