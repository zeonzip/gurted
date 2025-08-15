extends Node

const MAIN_COLOR = Color(27/255.0, 27/255.0, 27/255.0, 1)
const SECONDARY_COLOR = Color(43/255.0, 43/255.0, 43/255.0, 1)

const HOVER_COLOR = Color(0, 0, 0, 1)

const DEFAULT_CSS = """
body { text-base text-[#000000] text-left bg-white }
h1 { text-5xl font-bold }
h2 { text-4xl font-bold }
h3 { text-3xl font-bold }
h4 { text-2xl font-bold }
h5 { text-xl font-bold }
b { font-bold }
i { font-italic }
u { underline }
small { text-xl }
mark { bg-[#FFFF00] }
code { text-xl font-mono }
a { text-[#1a0dab] }
pre { text-xl font-mono }

button { text-[16px] bg-[#1b1b1b] rounded-md text-white hover:bg-[#2a2a2a] active:bg-[#101010] }
button[disabled] { bg-[#666666] text-[#999999] cursor-not-allowed }
"""