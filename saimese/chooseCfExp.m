function [final_exp, is_expand] = chooseCfExp(origin_exp, expand_exp, saimeseExp, spacethreshold, scoreparam)
origin_score = calculateCfExpScore(origin_exp, saimeseExp, scoreparam);
expand_score = calculateCfExpScore(expand_exp, saimeseExp, scoreparam);
relative_disp = calculateRelativeDisp(origin_exp, expand_exp);
threshold = exp((-relative_disp) * spacethreshold);
if origin_score < threshold * expand_score
    final_exp = expand_exp;
    is_expand = 1;
else
    final_exp = origin_exp;
    is_expand = 0;
end