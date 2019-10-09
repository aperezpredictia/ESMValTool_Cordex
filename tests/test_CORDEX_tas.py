from esmvalcore._main import main as esmvalcore_main


class Args:
    pass


def main():
    args = Args()
    args.recipe = "/home/pereza/git/c3s512/cordex-ia/recipes/recipe_C3S512_CORDEX_Ind_Ass_Cycle.yml"
    args.config_file = "/home/pereza/git/c3s512/cordex-ia/recipes/config-Antonio_tas.yml"
    args.synda_download = False
    args.skip_nonexistent = False
    args.diagnostics = ""
    args.max_datasets = None
    args.max_years = None

    esmvalcore_main(args)


if __name__ == "__main__":
    main()

