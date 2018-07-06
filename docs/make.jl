using Documenter, CESEarth

makedocs(format = :html, sitename="CES.Earth")

deploydocs(
    deps   = Deps.pip("pygments", "mkdocs", "python-markdown-math"),
    repo   = "github.com/Libbum/CES.Earth.git",
    julia  = "0.6"
)
