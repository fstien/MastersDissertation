# "Lasso Regularisation of Parametric Portfolio Policies"

## Abstract

We apply lasso regularisation to Parametric Portfolio Policies (PPP), which reduces the risk of overfitting when estimated with a large number of characteristics. Our model selects the most relevant characteristics in every time period, allowing different characteristics to be relevant at different times. We present a numerical method for estimation by imposing a constraint on the  optimisation problem. We estimate the model for foreign exchange (FX) using economic fundamentals as characteristics. We find that our model outperforms the baseline PPP model, with a lower standard deviation, a higher average return and a higher CE return. The results of model's variable selection and estimation is mostly consistent with the literature and theoretical predictions about the relationships between economic fundamentals and currency movements, and hence provides support for macroeconomic theories of FX. Our findings suggest that there exists predictability for FX movements in macroeconomic fundamentals.


## Content

1. Cross Vall Lasso: Cross Validation of lasso regularisation constraint in R. 

1. Cross Vall Ridge: Cross Validation of ridge regularisation constraint in R. 

3. PPP Modelling and analysis with elastic net regulatisation. 


## Estimation methodology

The estimation of theta is performed numerically through the differential evolution algorithm proposed by Brest et al. (2006). The algorithm takes as an input a function to minimise, which typically performs calculations on a dataset in the global environment (which depends on the input vector) and returns a value to the algorithm, which then proceeds to the next iteration until it has found an input vector which minimises the objective function. In this case the objective function is the average utility over the estimation periods which is computed by calculating the weights, returns and finally the utility in every period (which is then preceded by a minus sign since the algorithm performs minimisation whereas we want maximisation), whilst the input vector is the vector of coefficients. Unlike many other optimisers, it searches for a global maximum by maintaining a population of candidate solutions, which evolve randomly. As the evolutions are stochastic, convergence is stochastic and hence depends on the seed values. To ensure reproducibility, we set a seed of 1234 for all optimisations. It is implemented in R as part of the "DEoptimR" package. As the search space has 52 dimensions, convergence takes around two days with the default maximum number of iterations (52 x 200). For every model, we determine the number of iterations after testing the algorithm for a single observation, and observing the asymptotic behaviour of parameter estimates. As expected, we find that adding constraints significantly increases the number of iterations needed to ensure convergence. We set the number of iterations to 60 for the baseline PPP model and to 70 for the ridge regularisation. For the Lasso and Elastic Net, we set the number of iterations to 200. Indeed, adding the lasso constraint leads to an increase as the algorithm converges towards a corner of a hypercube in 52 dimensions. Since the parameters converge asymptotically to 0 for the characteristics that are dropped, estimates are infinitesimally close to 0. When plotting the kernel density of the parameters, a large spike is found around 0, indicating convergence. The search space is constrained to -1 and 1 for every element of $\theta$, which is not binding since the parameters do not converge to the boundaries. 

To evaluate the out-of-sample performance of our model, we estimate the parameters in every period using a rolling estimation window of past observations. Since we have 125 observations in total, we set to size of the estimation window to 30, to balance the tradeoff between the length of the estimation window and the number of out-of-sample returns, which we can use for inference. Since we are using quarterly data, there is a 3-month lag between the estimation window and returns. This ensures that all economic statistics used in our estimation would have been available at the time of the rebalancing decision.  The full backtest requires that the model is estimated 95 times (at every rebalancing) in a "for loop". Since every iteration of the for loop is independent of each other (there is no need to communicate between two given iterations), they can be performed by a separate thread and at the same time on different CPU cores, using the "parallel" R package. We use the Amazon EC2 instance service, which consists in virtual servers in the cloud, which can be rented at a per-hour price. This allows us to use an Ubuntu Linux server with 64 CPU cores (the run time is roughly proportional to the number of CPU cores due to the use of parallelism). 


## Outcome

Ranked 4th out of 59 students, awarded a grade of 78%. 

