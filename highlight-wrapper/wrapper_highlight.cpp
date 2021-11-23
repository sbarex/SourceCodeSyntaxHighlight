#include <__bit_reference>
#include "wrapper_highlight.h"
#include "highlight/src/include/codegenerator.h"
#include "highlight/src/include/datadir.h"
#include "highlight/src/include/version.h"
#include "highlight/src/include/syntaxreader.h"
#include <os/log.h>
#include <cstdio>
#include <iostream>
#include <regex>
#include <filesystem>

#define EXPORT __attribute__((visibility("default")))

static os_log_t sLog = os_log_create("org.sbarex.highlight-wrapper", "rendering");

static DataDir dataDir;
static highlight::CodeGenerator *generator = nullptr;

static string lastSuffix;

bool inlineCSS = false;
bool formattingEnabled;

static bool endsWith(const std::string& str, const std::string& suffix)
{
    auto str_size = str.size();
    auto suffix_size = suffix.size();
    return str_size >= suffix_size && 0 == str.compare(str_size-suffix_size, suffix_size, suffix);
}

vector <string> collectPluginPaths2(DataDir *data_Dir, const vector<string>& plugins)
{
    vector<string> absolutePaths;
    for (const auto & plugin : plugins) {
        if (Platform::fileExists(plugin)) {
            absolutePaths.push_back(plugin);
        } else {
            absolutePaths.push_back(data_Dir->getPluginPath(plugin+".lua"));
        }
    }
    return absolutePaths;
}

__unused char *get_highlight_version() {
    return strdup(highlight::Info::getVersion().c_str());
}
__unused char *get_highlight_website() {
    return strdup(highlight::Info::getWebsite().c_str());
}
__unused char *get_highlight_email() {
    return strdup(highlight::Info::getEmail().c_str());
}

__unused char *get_highlight_about() {
    string about =
            "highlight version " + highlight::Info::getVersion() +
            "\n Copyright (C) 2002-2021 Andre Simon <a dot simon at mailbox.org>" +
            "\n\n Argparser class" +
            "\n Copyright (C) 2006-2008 Antonio Diaz Diaz <ant_diaz at teleline.es>" +
            "\n\n Artistic Style Classes (3.1 rev. 672)" +
            "\n Copyright (C) 2006-2018 by Jim Pattee <jimp03 at email.com>" +
            "\n Copyright (C) 1998-2002 by Tal Davidson" +
            "\n\n Diluculum Lua wrapper (1.0)" +
            "\n Copyright (C) 2005-2013 by Leandro Motta Barros" +
            "\n\n xterm 256 color matching functions" +
            "\n Copyright (C) 2006 Wolfgang Frisch <wf at frexx.de>" +
            "\n\n PicoJSON library" +
            "\n Copyright (C) 2009-2010 Cybozu Labs, Inc." +
            "\n Copyright (C) 2011-2014 Kazuho Oku" +
            "\n\n This software is released under the terms of the GNU General " +
            "Public License." +
            "\n For more information about these matters, see the file named " +
            "COPYING.\n\n";
    return strdup(about.c_str());
}

__unused const char *get_lua_info() {
    return LUA_COPYRIGHT;
}

static bool is_initialized = false;

__unused int highlight_is_initialized() {
    return is_initialized ? 1 : 0;
}

__unused void highlight_init(const char *search_dir) {
    string pp = realpath(search_dir, nullptr);
    if (!endsWith(pp, "/")) {
        pp += Platform::pathSeparator;
    }
    os_log_debug(sLog, "Initializing search dirs with `%s`.", pp.c_str());
    dataDir.initSearchDirectories(pp);

    // call before printInstalledLanguages!
    dataDir.loadFileTypeConfig("filetypes");
    is_initialized = true;
}

int highlight_init_generator() {
    highlight_release_generator();
    os_log_debug(sLog, "Init generator.");
    generator = highlight::CodeGenerator::getInstance ( highlight::OutputType::HTML );

    generator->setHTMLAttachAnchors ( false );
    generator->setHTMLOrderedList ( false );
    generator->setHTMLInlineCSS ( inlineCSS );
    generator->setHTMLEnclosePreTag ( false );
    generator->setHTMLAnchorPrefix ( "l" );
    generator->setHTMLClassName ( "hl" );

    generator->setValidateInput ( false );
    generator->setNumberWrappedLines ( true );

    generator->setStyleInputPath ( "" );
    generator->setStyleOutputPath ( "" );
    generator->setIncludeStyle ( true );
    generator->setPrintLineNumbers ( false, 1 );
    generator->setPrintZeroes ( false );
    generator->setFragmentCode ( true );
    generator->setOmitVersionComment ( true );
    generator->setIsolateTags ( false );

    generator->setKeepInjections ( false);
    generator->setPreformatting ( highlight::WRAP_DISABLED,
                                  ( generator->getPrintLineNumbers() ) ?
                                  80 - 5 : 80,
                                  0 );

    //generator->setEncoding ( options.getEncoding() );
    generator->setBaseFont ( "" ) ;
    generator->setBaseFontSize ( "10" ) ;
    generator->setLineNumberWidth ( 5 );
    // generator->setStartingNestedLang( "");
    generator->disableTrailingNL(0);
    generator->setPluginParameter("");

    int getLineRangeStart = 0;
    int getLineRangeEnd = 0;
    if (getLineRangeStart>0 && getLineRangeEnd>0){
        generator->setStartingInputLine(getLineRangeStart);
        generator->setMaxInputLineCnt(getLineRangeEnd);
    }

    /** list of plugin file names */
    vector <string> userPlugins;
    const  vector <string> pluginFileList=collectPluginPaths2( &dataDir, userPlugins);

    for (const auto & i : pluginFileList) {
        if ( !generator->initPluginScript(i) ) {
            os_log_error(sLog, "%{public}s in %{public}s", generator->getPluginScriptError().c_str(), i.c_str());

            return EXIT_FAILURE;
        }
    }

/*
    if ( options.printOnlyStyle() ) {
        if (!options.formatSupportsExtStyle()) {
            cerr << "highlight: output format supports no external styles.\n";
            return EXIT_FAILURE;
        }
        bool useStdout =  getStyleOutFilename =="stdout" || options.forceStdout();
        string cssOutFile=options.getOutDirectory()  + getStyleOutFilename;
        bool success=generator->printExternalStyle ( useStdout?"":cssOutFile );
        if ( !success ) {
            cerr << "highlight: Could not write " << cssOutFile <<".\n";
            return EXIT_FAILURE;
        }
        return EXIT_SUCCESS;
    }
    */

    string getIndentScheme;
    formattingEnabled = generator->initIndentationScheme ( getIndentScheme );
    if ( !formattingEnabled && !getIndentScheme.empty() ) {
        os_log_error(sLog, "Undefined indentation scheme %{public}s.", getIndentScheme.c_str());
        /*
        cerr << "highlight: Undefined indentation scheme "
             << getIndentScheme
             << ".\n";
         */
        return EXIT_FAILURE;
    }

    return EXIT_SUCCESS;
}

void highlight_release_generator(void) {
    delete generator;
    generator = nullptr;
}

__unused void highlight_format_style(void *context, ResultCallback callback, const char *background) {
    int exit_code = 0;
    char *content = highlight_format_style2(&exit_code, background);
    callback(context, content, 0);
    free(content);
}

EXPORT char *highlight_format_style2(int *exit_code, const char *background)
{
    if (!generator) {
        if (highlight_init_generator() != EXIT_SUCCESS) {
            *exit_code = EXIT_FAILURE;
            return nullptr;
        }
    }

    string content = generator->getStyleDefinition() + "\n" + generator->readUserStyleDef();

    if (background != nullptr) {
        std::regex reg("background-color:#[a-f0-9]{6};");
        string replace = background;
        if (!replace.empty()) {
            replace = "background-color: " + string(background) + ";";
        }
        content = regex_replace(content, reg, replace);
    }

    *exit_code = EXIT_SUCCESS;
    return strdup(content.c_str());
}

__unused int highlight_list_themes( void *context, ResultThemeListCallback callback) {
    int count;
    ReleaseThemeInfoList release;
    HThemeInfo **themes;
    int exit_code = highlight_list_themes2(&themes, &count, &release);
    callback(context, (const HThemeInfo **)themes, count, exit_code);

    release(themes, count);

    return exit_code;
}

static HThemeInfo *allocate_theme_info() {
    auto *theme_info = (HThemeInfo *)calloc(1, sizeof(HThemeInfo));
    theme_info->name = nullptr;
    theme_info->desc = nullptr;
    theme_info->path = nullptr;
    return theme_info;
}

static void release_theme_info(HThemeInfo *theme_info) {
    free(theme_info->name);
    theme_info->name = nullptr;
    free(theme_info->desc);
    theme_info->desc = nullptr;
    free(theme_info->path);
    theme_info->path = nullptr;

    free(theme_info);
}

static void release_theme_info_list(HThemeInfo **themes, int count) {
    int n;
    for (n = 0; n < count; n++) {
        release_theme_info(themes[n]);
    }
    free(themes);
}

int highlight_list_themes2(HThemeInfo ***theme_list, int *count, ReleaseThemeInfoList *release) {
    *theme_list = nullptr;
    *count = 0;
    *release = release_theme_info_list;

    string base_path16 = dataDir.getThemePath("", true);
    string where = dataDir.getThemePath("");
    string wildcard = "*.theme";
    vector <string> filePaths;
    string searchDir = where + wildcard;

    bool directoryOK = Platform::getDirectoryEntries ( filePaths, searchDir, true );
    if ( !directoryOK ) {
        os_log_error(sLog, "Could not access directory %{public}s.", searchDir.c_str());
        return EXIT_FAILURE;
    }

    sort ( filePaths.begin(), filePaths.end() );
    string suffix, desc;
    Diluculum::LuaValueMap categoryMap;

    std::set<string> categoryNames;

    istringstream valueStream;

    *count = filePaths.size();
    auto **themes = (HThemeInfo **)calloc(*count, sizeof(HThemeInfo *));
    int j = 0;

    for (const auto& filePath : filePaths) {
        HThemeInfo *theme;
        try {
            Diluculum::LuaState ls;
            highlight::SyntaxReader::initLuaState(ls, filePath, "");
            ls.doFile(filePath);
            desc = ls["Description"].value().asString();

            theme = allocate_theme_info();
            
            if (ls["Categories"].value() !=Diluculum::Nil) {
                categoryMap = ls["Categories"].value().asTable();
                for(Diluculum::LuaValueMap::const_iterator it = categoryMap.begin(); it != categoryMap.end(); ++it)
                {
                    string category = it->second.asString();
                    if (category == "light") {
                        theme->appearance = 1;
                    } else if (category == "dark") {
                        theme->appearance = 2;
                    }
                }
            }

            suffix = (filePath).substr ( where.length() ) ;
            suffix = suffix.substr ( 0, suffix.length()- wildcard.length() + 1);

            theme->name = strdup(suffix.c_str());
            theme->desc = strdup(desc.c_str());
            theme->path = strdup(filePath.c_str());
            theme->base16 = filePath.rfind(base_path16, 0) == 0 ? 1 : 0;

            themes[j] = theme;
            j++;
        } catch (std::runtime_error &error) {
            os_log_error(sLog, "Failed to read '%{public}s': %{public}s", filePath.c_str(), error.what());
            release_theme_info(theme);
        }
    }

    *count = j;
    *theme_list = themes;

    return EXIT_SUCCESS;
}

static HThemeProperty *parse_theme_property(Diluculum::LuaValueMap lua) {
    auto *property = (HThemeProperty *)calloc(1, sizeof(HThemeProperty));
    Diluculum::LuaValue value;
    bool override = true;
    value = lua["Colour"];
    if (value != Diluculum::Nil) {
        property->color = strdup(value.asString().c_str());
        override = false;
    }

    value = lua["Bold"];
    if (value != Diluculum::Nil) {
        property->bold = value.asBoolean();
        override = false;
    } else {
        property->bold = -1;
    }

    value = lua["Italic"];
    if (value != Diluculum::Nil) {
        property->italic = value.asBoolean();
        override = false;
    } else {
        property->italic = -1;
    }

    value = lua["Underline"];
    if (value != Diluculum::Nil) {
        property->underline = value.asBoolean();
        override = false;
    } else {
        property->underline = -1;
    }

    property->numberOfCustomStyles = 0;

    if (lua["Custom"] != Diluculum::Nil) {
        int idx=1;
        auto customFormats = lua["Custom"];

        while (customFormats[idx] != Diluculum::Nil) {
            property->numberOfCustomStyles ++;
            idx++;
        }

        idx = 0;
        property->formats = (char **)calloc(property->numberOfCustomStyles, sizeof(char *));
        property->styles = (char **)calloc(property->numberOfCustomStyles, sizeof(char *));
        property->override = (int *)calloc(property->numberOfCustomStyles, sizeof(int));
        for (idx = 0; idx < property->numberOfCustomStyles; idx++) {
            property->formats[idx] = strdup(customFormats[idx+1]["Format"].asString().c_str());
            property->styles[idx] = strdup(customFormats[idx+1]["Style"].asString().c_str());
            property->override[idx] = override;
        }
    }

    return property;
}

static void release_theme_property(HThemeProperty *property) {
    if (property == nullptr) {
        return;
    }
    free(property->color);
    property->color = nullptr;
    
    for (int i=0; i<property->numberOfCustomStyles; i++) {
        free(property->formats[i]);
        free(property->styles[i]);
    }
    free(property->formats);
    property->formats = nullptr;
    free(property->styles);
    property->styles = nullptr;

    free(property->override);
    property->override = nullptr;
    
    property->numberOfCustomStyles = 0;
    
    free(property);
}

/**
 * Allocate an empty theme.
 * @return
 */
static HTheme *allocate_theme() {
    auto *theme = (HTheme *)calloc(1, sizeof(HTheme));
    theme->name = nullptr;
    theme->desc = nullptr;
    theme->path = nullptr;

    theme->appearance = HThemeAppearance::not_set;
    theme->standalone = 0;
    theme->base16 = 0;

    theme->plain = nullptr;
    theme->canvas = nullptr;
    theme->number = nullptr;
    theme->string = nullptr;
    theme->escape = nullptr;
    theme->preProcessor = nullptr;
    theme->stringPreProc = nullptr;
    theme->blockComment = nullptr;
    theme->lineComment = nullptr;
    theme->lineNum = nullptr;
    theme->operatorProp = nullptr;
    theme->interpolation = nullptr;

    theme->hover = nullptr;
    theme->error = nullptr;
    theme->errorMessage = nullptr;
    
    theme->lspType = nullptr;
    theme->lspClass = nullptr;
    theme->lspStruct = nullptr;
    theme->lspInterface = nullptr;
    theme->lspParameter = nullptr;
    theme->lspVariable = nullptr;
    theme->lspEnumMember = nullptr;
    theme->lspFunction = nullptr;
    theme->lspMethod = nullptr;
    theme->lspKeyword = nullptr;
    theme->lspNumber = nullptr;
    theme->lspRegexp = nullptr;
    theme->lspOperator = nullptr;

    theme->keywords = nullptr;
    theme->keyword_count = 0;
    return theme;
}

/**
 * Release a theme.
 * @param theme
 */
static void release_theme(HTheme *theme) {
    if (theme == nullptr) {
        return;
    }
    free(theme->name);
    theme->name = nullptr;
    free(theme->desc);
    theme->desc = nullptr;
    free(theme->path);
    theme->path = nullptr;

    release_theme_property(theme->plain);
    theme->plain = nullptr;
    release_theme_property(theme->canvas);
    theme->canvas = nullptr;
    release_theme_property(theme->number);
    theme->number = nullptr;
    release_theme_property(theme->string);
    theme->string = nullptr;
    release_theme_property(theme->escape);
    theme->escape = nullptr;
    release_theme_property(theme->preProcessor);
    theme->preProcessor = nullptr;
    release_theme_property(theme->stringPreProc);
    theme->stringPreProc = nullptr;
    release_theme_property(theme->blockComment);
    theme->blockComment = nullptr;
    release_theme_property(theme->lineComment);
    theme->lineComment = nullptr;
    release_theme_property(theme->lineNum);
    theme->lineNum = nullptr;
    release_theme_property(theme->operatorProp);
    theme->operatorProp = nullptr;
    release_theme_property(theme->interpolation);
    theme->interpolation = nullptr;

    release_theme_property(theme->hover);
    theme->hover = nullptr;
    release_theme_property(theme->error);
    theme->error = nullptr;
    release_theme_property(theme->errorMessage);
    theme->errorMessage = nullptr;
    
    release_theme_property(theme->lspType);
    theme->lspType = nullptr;
    release_theme_property(theme->lspClass);
    theme->lspClass = nullptr;
    release_theme_property(theme->lspStruct);
    theme->lspStruct = nullptr;
    release_theme_property(theme->lspInterface);
    theme->lspInterface = nullptr;
    release_theme_property(theme->lspParameter);
    theme->lspParameter = nullptr;
    release_theme_property(theme->lspVariable);
    theme->lspVariable = nullptr;
    release_theme_property(theme->lspEnumMember);
    theme->lspEnumMember = nullptr;
    release_theme_property(theme->lspFunction);
    theme->lspFunction = nullptr;
    release_theme_property(theme->lspMethod);
    theme->lspMethod = nullptr;
    release_theme_property(theme->lspKeyword);
    theme->lspKeyword = nullptr;
    release_theme_property(theme->lspNumber);
    theme->lspNumber = nullptr;
    release_theme_property(theme->lspRegexp);
    theme->lspRegexp = nullptr;
    release_theme_property(theme->lspOperator);
    theme->lspOperator = nullptr;
    
    int i;
    for (i=0; i<theme->keyword_count; i++) {
        release_theme_property(theme->keywords[i]);
        theme->keywords[i] = nullptr;
    }
    free(theme->keywords);
    theme->keywords = nullptr;
    theme->keyword_count = 0;

    free(theme);
}

__unused int highlight_get_theme( const char *theme_name, void *context, ResultThemeCallback callback) {
    int exit_code = 0;
    ReleaseTheme release = nullptr;
    HTheme *theme = highlight_get_theme2(theme_name, &exit_code, &release);
    callback(context, theme, exit_code);

    (*release)(theme);
    return exit_code;
}

HTheme *highlight_get_theme2( const char *theme_name, int *exit_code, ReleaseTheme *release) {
    *release = release_theme;
    if (theme_name == nullptr || strlen(theme_name) == 0) {
        *exit_code = EXIT_FAILURE;
        return nullptr;
    }
    
    string themeFile;
    if (Platform::fileExists(theme_name)) {
        themeFile = std::__fs::filesystem::canonical(theme_name);
    } else {
        string full_theme_name = theme_name;
        if (!endsWith(full_theme_name, ".theme")) {
            full_theme_name += ".theme";
        }

        themeFile = std::__fs::filesystem::canonical(dataDir.getThemePath ( full_theme_name, false ));
    }

    //string themesDir = dataDir.getThemePath("");
    //string themeFile = themesDir + theme_name + ".theme";

    string name = themeFile;

    // Remove directory if present.
    string::size_type Pos = name.find_last_of( Platform::pathSeparator );
    if ( Pos != string::npos ) {
        name.erase(0, Pos + 1);
    }
    // Remove extension if present.
    const size_t period_idx = name.rfind('.');
    if (string::npos != period_idx)
    {
        name.erase(period_idx);
    }

    Diluculum::LuaState ls;
    highlight::SyntaxReader::initLuaState(ls, themeFile, "");
    try {
        ls.doFile(themeFile);
    } catch(std::runtime_error &error) {
        os_log_error(sLog, "Unable to parse lua file '%{public}s: %{public}s.'", themeFile.c_str(), error.what());
        *exit_code = EXIT_FAILURE;
        return nullptr;
    }
    HTheme *theme = allocate_theme();

    theme->name = strdup(name.c_str());
    theme->desc = strdup(ls["Description"].value().asString().c_str());
    theme->path = strdup(themeFile.c_str());

    string base_path = dataDir.getThemePath("", false);
    theme->standalone = themeFile.rfind(base_path, 0) == 0 ? 1 : 0;
    string base_path16 = dataDir.getThemePath("", true);
    theme->base16 = themeFile.rfind(base_path16, 0) == 0 ? 1 : 0;

    Diluculum::LuaValue prop;

    prop = ls["Categories"].value();
    if (prop != Diluculum::Nil) {
        Diluculum::LuaValueMap categoryMap;
        categoryMap = prop.asTable();
        for (Diluculum::LuaValueMap::const_iterator it = categoryMap.begin(); it != categoryMap.end(); ++it)
        {
            string category = it->second.asString();
            if (category == "light") {
                theme->appearance = HThemeAppearance::light;
            } else if (category == "dark") {
                theme->appearance = HThemeAppearance::dark;
            }
        }
    }

    prop = ls["Default"].value();
    if (prop != Diluculum::Nil) {
        theme->plain = parse_theme_property(prop.asTable());
    }
    prop = ls["Canvas"].value();
    if (prop != Diluculum::Nil) {
        theme->canvas = parse_theme_property(prop.asTable());
    }
    prop = ls["Number"].value();
    if (prop != Diluculum::Nil) {
        theme->number = parse_theme_property(prop.asTable());
    }
    prop = ls["String"].value();
    if (prop != Diluculum::Nil) {
        theme->string = parse_theme_property(prop.asTable());
    }
    prop = ls["Escape"].value();
    if (prop != Diluculum::Nil) {
        theme->escape = parse_theme_property(prop.asTable());
    }
    prop = ls["PreProcessor"].value();
    if (prop != Diluculum::Nil) {
        theme->preProcessor = parse_theme_property(prop.asTable());
    }
    prop = ls["StringPreProc"].value();
    if (prop != Diluculum::Nil) {
        theme->stringPreProc = parse_theme_property(prop.asTable());
    }
    prop = ls["BlockComment"].value();
    if (prop != Diluculum::Nil) {
        theme->blockComment = parse_theme_property(prop.asTable());
    }
    prop = ls["LineComment"].value();
    if (prop != Diluculum::Nil) {
        theme->lineComment = parse_theme_property(prop.asTable());
    }
    prop = ls["LineNum"].value();
    if (prop != Diluculum::Nil) {
        theme->lineNum = parse_theme_property(prop.asTable());
    }
    prop = ls["Operator"].value();
    if (prop != Diluculum::Nil) {
        theme->operatorProp = parse_theme_property(prop.asTable());
    }
    prop = ls["Interpolation"].value();
    if (prop != Diluculum::Nil) {
        theme->interpolation = parse_theme_property(prop.asTable());
    }

    prop = ls["Hover"].value();
    if (prop != Diluculum::Nil) {
        theme->hover = parse_theme_property(prop.asTable());
    }
    prop = ls["Error"].value();
    if (prop != Diluculum::Nil) {
        theme->error = parse_theme_property(prop.asTable());
    }
    prop = ls["ErrorMessage"].value();
    if (prop != Diluculum::Nil) {
        theme->errorMessage = parse_theme_property(prop.asTable());
    }

    prop = ls["Keywords"].value();
    if (prop != Diluculum::Nil) {
        Diluculum::LuaValueMap keywordsMap;
        keywordsMap = prop.asTable();

        int i = 0;
        for (Diluculum::LuaValueMap::const_iterator it = keywordsMap.begin(); it != keywordsMap.end(); ++it)
        {
            i++;
        }

        theme->keywords = (HThemeProperty **)calloc(i, sizeof(HThemeProperty *));
        theme->keyword_count = i;

        i = 0;
        for (Diluculum::LuaValueMap::const_iterator it = keywordsMap.begin(); it != keywordsMap.end(); ++it)
        {
            Diluculum::LuaValueMap t;
            t = it->second.asTable();
            // printf("->%s\n", t["Colour"].asString().c_str());
            theme->keywords[i] = parse_theme_property(t);
            i++;
        }
    }
    
    prop = ls["SemanticTokenTypes"].value();
    if (prop != Diluculum::Nil) {
        Diluculum::LuaValueMap tokensMap;
        tokensMap = prop.asTable();

        for (Diluculum::LuaValueMap::const_iterator it = tokensMap.begin(); it != tokensMap.end(); ++it)
        {
            Diluculum::LuaValueMap t;
            t = it->second.asTable();
            string tokenType = t["Type"].asString();
            Diluculum::LuaValueMap style;
            style = t["Style"].asTable();
            
            if (tokenType == "type") {
                theme->lspType = parse_theme_property(style);
            } else if (tokenType == "class") {
                theme->lspClass = parse_theme_property(style);
            } else if (tokenType == "struct") {
                theme->lspStruct = parse_theme_property(style);
            } else if (tokenType == "interface") {
                theme->lspInterface = parse_theme_property(style);
            } else if (tokenType == "parameter") {
                theme->lspParameter = parse_theme_property(style);
            } else if (tokenType == "variable") {
                theme->lspVariable = parse_theme_property(style);
            } else if (tokenType == "enumMember") {
                theme->lspEnumMember = parse_theme_property(style);
            } else if (tokenType == "function") {
                theme->lspFunction = parse_theme_property(style);
            } else if (tokenType == "method") {
                theme->lspMethod = parse_theme_property(style);
            } else if (tokenType == "keyword") {
                theme->lspKeyword = parse_theme_property(style);
            } else if (tokenType == "number") {
                theme->lspNumber = parse_theme_property(style);
            } else if (tokenType == "regexp") {
                theme->lspRegexp = parse_theme_property(style);
            } else if (tokenType == "operator") {
                theme->lspOperator = parse_theme_property(style);
            } else {
                os_log_error(sLog, "Unable to parse SemanticTokenTypes token: %{public}s.", tokenType.c_str());
            }
        }
    }

    *exit_code = EXIT_SUCCESS;
    return theme;
}

/**
 * Save a theme property to file.
 * @param file
 * @param name Name of the property.
 * @param property
 * @return
 */
static int save_theme_property(ofstream &file, const char *name, HThemeProperty *property) {
    if (property == nullptr) {
        return 0;
    }
    if (name != nullptr) {
        file << name
             << "\t=";
    }
    file << "\t{ ";
    int i = 0;
    if (property->color) {
        file << "Colour=\""
             << property->color
             << "\"";
        i++;
    }
    if (property->bold >= 0) {
        file << (i > 0 ? ", " : "")
             << "Bold="
             << (property->bold ? "true" : "false");
    }
    if (property->italic >= 0) {
        file << (i > 0 ? ", " : "")
             << "Italic="
             << (property->italic ? "true" : "false");
    }
    if (property->underline >= 0) {
        file << (i > 0 ? ", " : "")
             << "Underline="
             << (property->underline ? "true" : "false");
    }
    file << " }";
    if (name != nullptr) {
        file << "\n";
    }
    return 1;
}

__unused int highlight_save_theme( const char *filename, const HTheme *theme) {
    ofstream file;
    file.open(filename, ios::out);
    if (!file.is_open()) {
        return EXIT_FAILURE;
    }

    file << "Description\t=\t\""
         << theme->desc
         << "\"\n";
    file << "Categories\t=\t{"
         << (theme->appearance > 0 ? (theme->appearance == 1 ? "\"light\"" : "\"dark\"") : "")
         << "}\n\n";
    save_theme_property(file, "Default", theme->plain);
    save_theme_property(file, "Canvas", theme->canvas);
    save_theme_property(file, "Number", theme->number);
    save_theme_property(file, "String", theme->string);
    save_theme_property(file, "Escape", theme->escape);
    save_theme_property(file, "PreProcessor", theme->preProcessor);
    save_theme_property(file, "StringPreProc", theme->stringPreProc);
    save_theme_property(file, "BlockComment", theme->blockComment);
    save_theme_property(file, "LineComment", theme->lineComment);
    save_theme_property(file, "LineNum", theme->lineNum);
    save_theme_property(file, "Operator", theme->operatorProp);
    save_theme_property(file, "Interpolation", theme->interpolation);

    save_theme_property(file, "Hover", theme->hover);
    save_theme_property(file, "Error", theme->error);
    save_theme_property(file, "ErrorMessage", theme->errorMessage);
    
    file << "\n";

    file << "Keywords = {\n";
    int i;
    for (i = 0; i < theme->keyword_count; i++) {
        if (save_theme_property(file, nullptr, theme->keywords[i]) > 0) {
            if (i+1 < theme->keyword_count) {
                file << ",";
            }
            file << "\n";
        }
    }
    file << "}\n\n";
    
    file << "SemanticTokenTypes = {\n";
    file << "\t{ Type = 'type', Style = ";
    save_theme_property(file, nullptr, theme->lspType);
    file << " },\n";
    file << "\t{ Type = 'class', Style = ";
    save_theme_property(file, nullptr, theme->lspClass);
    file << " },\n";
    file << "\t{ Type = 'struct', Style = ";
    save_theme_property(file, nullptr, theme->lspStruct);
    file << " },\n";
    file << "\t{ Type = 'interface', Style = ";
    save_theme_property(file, nullptr, theme->lspInterface);
    file << " },\n";
    file << "\t{ Type = 'parameter', Style = ";
    save_theme_property(file, nullptr, theme->lspParameter);
    file << " },\n";
    file << "\t{ Type = 'variable', Style = ";
    save_theme_property(file, nullptr, theme->lspVariable);
    file << " },\n";
    file << "\t{ Type = 'enumMember', Style = ";
    save_theme_property(file, nullptr, theme->lspEnumMember);
    file << " },\n";
    file << "\t{ Type = 'function', Style = ";
    save_theme_property(file, nullptr, theme->lspFunction);
    file << " },\n";
    file << "\t{ Type = 'method', Style = ";
    save_theme_property(file, nullptr, theme->lspMethod);
    file << " },\n";
    file << "\t{ Type = 'keyword', Style = ";
    save_theme_property(file, nullptr, theme->lspKeyword);
    file << " },\n";
    file << "\t{ Type = 'number', Style = ";
    save_theme_property(file, nullptr, theme->lspNumber);
    file << " },\n";
    file << "\t{ Type = 'regexp', Style = ";
    save_theme_property(file, nullptr, theme->lspRegexp);
    file << " },\n";
    file << "\t{ Type = 'operator', Style = ";
    save_theme_property(file, nullptr, theme->lspOperator);
    file << " },\n";
    file << "}\n";
    file.close();

    return EXIT_SUCCESS;
}

__unused int highlight_list_plugins( void *context, ResultPluginListCallback callback) {
    int count;
    ReleasePluginInfoList release;
    HPluginInfo **plugins;
    int exit_code = highlight_list_plugins2(&plugins, &count, &release);
    callback(context, (const HPluginInfo **)plugins, count, exit_code);

    release(plugins, count);

    return exit_code;
}

static HPluginInfo *allocate_plugin_info() {
    auto *plugin_info = (HPluginInfo *)calloc(1, sizeof(HPluginInfo));
    plugin_info->name = nullptr;
    plugin_info->desc = nullptr;
    plugin_info->path = nullptr;
    return plugin_info;
}

static void release_plugin_info(HPluginInfo *plugin_info) {
    free(plugin_info->name);
    plugin_info->name = nullptr;
    free(plugin_info->desc);
    plugin_info->desc = nullptr;
    free(plugin_info->path);
    plugin_info->path = nullptr;

    free(plugin_info);
}

static void release_plugin_info_list(HPluginInfo **plugins, int count) {
    int n;
    for (n = 0; n < count; n++) {
        release_plugin_info(plugins[n]);
    }
    free(plugins);
}

int highlight_list_plugins2(HPluginInfo ***plugin_list, int *count, ReleasePluginInfoList *release) {
    *plugin_list = nullptr;
    *count = 0;
    *release = release_plugin_info_list;

    string where = dataDir.getPluginPath("");
    string wildcard = "*.lua";
    vector <string> filePaths;
    string searchDir = where + wildcard;

    bool directoryOK = Platform::getDirectoryEntries ( filePaths, searchDir, true );
    if ( !directoryOK ) {
        os_log_error(sLog, "Could not access directory %{public}s.", searchDir.c_str());
        return EXIT_FAILURE;
    }

    sort ( filePaths.begin(), filePaths.end() );
    string suffix, desc;
    Diluculum::LuaValueMap categoryMap;

    std::set<string> categoryNames;

    istringstream valueStream;

    *count = filePaths.size();
    auto **plugins = (HPluginInfo **)calloc(*count, sizeof(HPluginInfo *));
    int j = 0;

    for (const auto& filePath : filePaths) {
        HPluginInfo *plugin;
        try {
            plugin = allocate_plugin_info();

            Diluculum::LuaState ls;
            highlight::SyntaxReader::initLuaState(ls, filePath, "");
            ls.doFile(filePath);
            desc = ls["Description"].value().asString();

            suffix = (filePath).substr ( where.length() ) ;
            suffix = suffix.substr ( 0, suffix.length()- wildcard.length() + 1);

            plugin->name = strdup(suffix.c_str());
            plugin->desc = strdup(ls["Description"].value().asString().c_str());
            plugin->path = strdup(filePath.c_str());

            plugins[j] = plugin;
            j++;
        } catch (std::runtime_error &error) {
            os_log_error(sLog, "Failed to read '%{public}s': %{public}s", filePath.c_str(), error.what());
            release_plugin_info(plugin);
        }
    }
    
    *count = j;
    *plugin_list = plugins;

    return EXIT_SUCCESS;
}


__unused int highlight_get_supported_languages(void* context, LanguageCallback callback) {
    vector <string> filePaths;
    string where = dataDir.getLangPath("");
    string wildcard = "*.lang";
    std::string searchDir = where + wildcard;
    bool directoryOK = Platform::getDirectoryEntries ( filePaths, searchDir, true );
    if ( !directoryOK ) {
        return -1;
    }

    sort ( filePaths.begin(), filePaths.end() );
    string suffix, desc;

    int n = 0;
    for (auto & filePath : filePaths) {
        try {
            Diluculum::LuaState ls;
            highlight::SyntaxReader::initLuaState(ls, filePath,"");
            ls.doFile(filePath);

            desc = ls["Description"].value().asString();

            suffix = filePath.substr ( where.length() ) ;
            suffix = suffix.substr ( 0, suffix.length()- wildcard.length() + 1);

            vector<string> extensions;
            extensions.push_back(suffix);

            for (auto & it : dataDir.assocByExtension) {
                if (it.second==suffix ) {
                    extensions.push_back(it.first);
                }
            }

            lang_def lang;
            lang.name = desc.c_str();
            lang.n = extensions.size();
            lang.extensions = (const char **)calloc(lang.n+1, sizeof (char *)); // +1 last item is null.
            int i;
            for (i=0; i<lang.n; i++) {
                lang.extensions[i] = extensions[i].c_str();
            }

            callback(context, n, lang);
            free(lang.extensions);
            n++;

        } catch (std::runtime_error &error) {
            os_log_error(sLog, "Failed to read '%{public}s': %{public}s", filePath.c_str(), error.what());
        }
    }
    return n;
}

__unused char *highlight_is_file_supported(const char *filename) {
    string suffix = dataDir.guessFileType ( dataDir.getFileSuffix ( filename ), filename );

    if (highlight_is_extension_supported(suffix.c_str()) == EXIT_SUCCESS) {
        return strdup(suffix.c_str());
    } else {
        return nullptr;
    }
}

__unused char *highlight_is_extension_supported(const char *extension) {
    string suffix = StringTools::change_case(extension);

    if (dataDir.assocByExtension.count(suffix)) {
        suffix = dataDir.assocByExtension[suffix];
    }

    string langDefPath = dataDir.getLangPath ( suffix+".lang" );
    if (!Platform::fileExists(langDefPath)) {
        return nullptr;
    }

    auto *syntax = new highlight::SyntaxReader();
    highlight::LoadResult result = syntax->load(langDefPath, "", highlight::HTML);
    delete syntax;

    if ( result != highlight::LOAD_OK ) {
        return nullptr;
    }

    return strdup(suffix.c_str());
}
