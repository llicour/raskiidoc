%%
%% This style is derived from the docbook one.
%%
\NeedsTeXFormat{LaTeX2e}
\ProvidesPackage{asciidoc}[2008/06/05 AsciiDoc DocBook Style]
%% Just use the original package and pass the options.
\RequirePackageWithOptions{docbook}

% Sidebar is a boxed minipage that can contain verbatim.
% Changed shadow box to double box.
\renewenvironment{sidebar}[1][0.95\textwidth]{
  \hspace{0mm}\newline%
  \noindent\begin{Sbox}\begin{minipage}{#1}%
  \setlength\parskip{\medskipamount}%
}{
  \end{minipage}\end{Sbox}\doublebox{\TheSbox}%
}

% For DocBook literallayout elements, see `./dblatex/dblatex-readme.txt`.
\usepackage{alltt}

%% Redefine the paragraph layout
\setlength\parskip{\medskipamount}
\setlength\parindent{10pt}

\newcommand{\HRule}{\rule{\linewidth}{0.5mm}}

% \usepackage{fancyhdr}
% \pagestyle{fancy}
% \fancyhf{} % clear all header and footer fields
% \fancyhead[ro,le]{\bfseries The performance of new graduates}
% \fancyfoot[LE,RO]{\thepage}
% \fancyfoot[LO,CE]{From: K. Grant}
% \fancyfoot[CO,RE]{To: Dean A. Smith}
% \renewcommand{\headrulewidth}{0.4pt}
% \renewcommand{\footrulewidth}{0.4pt}

% Fancy header/footer for the first page
\chead[]{}
\lhead[]{}
\rhead[]{\@ifundefined{chaptername}{test chapter name}{\chaptername}}
\lfoot[]{\@ifundefined{DBKpublisher}{<%= $conf["vars::Pages::FooterLeft"] %>}{\DBKpublisher}}
\rfoot[]{\@ifundefined{DBKpublisher}{<%= $conf["vars::Pages::FooterRight"] %>}{\DBKpublisher}}
\cfoot[]{\textsf{<%= $conf["vars::Pages::FooterCenter"] %>}}
% Fancy header/footer for the front matter
\def\DBKcheadfront{%
	\DBKtitle{} \edhead%
}
% Fancy header/footer for the doc body
\def\DBKcheadbody{%
	\DBKtitle{} \edhead%
}
% \lhead[]{}
% \rhead[]{}
% \renewcommand{\headrulewidth}{0.4pt}
% \renewcommand{\footrulewidth}{0.4pt}



\renewcommand{\maketitle}{
	\begin{titlepage}%
	\thispagestyle{empty} % Removes header and footer from the cover page
	 %\thispagestyle{plain} % Adds header and footer to the cover page
		\begin{center}%
			% Upper part of the page
      <% if not $conf["vars::CoverPage::Logo1Filename"].nil? %>
			\includegraphics[width=<%= $conf["vars::CoverPage::Logo1Size"] %>\textwidth]{<%= $conf["vars::CoverPage::Logo1Filename"] %>}\\[5cm]
      <% end %>
      <% if not $conf["vars::CoverPage::TitleLevel2"].nil? %>
			\textsc{\LARGE <%= $conf["vars::CoverPage::TitleLevel2"] %>}\\[1.5cm]
      <% end %>
      <% if not $conf["vars::CoverPage::TitleLevel3"].nil? %>
			\textsc{\Large <%= $conf["vars::CoverPage::TitleLevel3"] %>}\\[0.5cm]
      <% end %>
			% Title
			\HRule \\[0.4cm]
			{ \huge \bfseries <%= $conf["vars::CoverPage::TitleLevel1"] %>}\\[0.4cm]
			\HRule \\[1.5cm]
			\vfill
			% Author and company
			\begin{minipage}{0.4\textwidth}%
				\begin{flushleft} \large
					\emph{<%= $conf["vars::CoverPage::LabelBottomLeft"] %>}\\
				<%= $conf["vars::CoverPage::TextBottomLeft"] %>
				\end{flushleft}
			\end{minipage}
			\begin{minipage}{0.4\textwidth}
				\begin{flushright} \large
					\emph{<%= $conf["vars::CoverPage::LabelBottomRight"] %>} \\
				<%= $conf["vars::CoverPage::TextBottomRight"] %>
				\end{flushright}
			\end{minipage}
			% Bottom of the page
			\begin{minipage}{0.4\textwidth}
				\begin{center}
					\large <%= $conf["vars::CoverPage::TextBottomCenter"] %>
				\end{center}
			\end{minipage}
		\end{center}%
	\end{titlepage}%
}% 
