using Documenter, LaxZonedDateTimes

makedocs(
    modules = [LaxZonedDateTimes],
    format = Documenter.HTML(prettyurls = get(ENV, "CI", nothing) == "true"),
    pages = [
        "Home" => "index.md",
    ],
    repo = "https://github.ca/JuliaTime/LaxZonedDateTimes.jl/blob/{commit}{path}#L{line}",
    sitename = "LaxZonedDateTimes.jl",
    authors = "Curtis Vogt, Gem Newman",
    assets = [
        "assets/invenia.css"
    ],
    checkdocs = :none,
    strict = true,
)

deploydocs(;
    repo="github.com/JuliaTime/LaxZonedDateTimes.jl"
)
