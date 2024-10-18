import {addLiquidityHandle} from "./Hepler";
import 'dotenv/config'
const mmm314 = process.env.MMM314 || ""
async function main() {
    await addLiquidityHandle(mmm314);
}
main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});