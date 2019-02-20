using Documenter, LaxZonedDateTimes

makedocs(
    modules = [LaxZonedDateTimes],
    format = Documenter.HTML(prettyurls = get(ENV, "CI", nothing) == "true"),
    pages = [
        "Home" => "index.md",
    ],
    repo = "https://gitlab.invenia.ca/invenia/LaxZonedDateTimes.jl/blob/{commit}{path}#L{line}",
    sitename = "LaxZonedDateTimes.jl",
    authors = "Curtis Vogt, Gem Newman",
    assets = [
        "assets/invenia.css"
    ],
    checkdocs = :none,
    strict = true,
)

